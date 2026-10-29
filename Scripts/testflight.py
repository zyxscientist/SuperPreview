#!/usr/bin/env python3
"""Archive, upload, and verify a SuperPreview internal TestFlight build."""
import argparse
import base64
import json
import os
from pathlib import Path
import plistlib
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = Path(__file__).resolve().parent.parent
APP_ID = '6557056004'
GROUP_ID = '801f635c-feb0-4443-a209-9fe44814b2fa'
TEAM_ID = '2P736NN28T'
API = 'https://api.appstoreconnect.apple.com/v1/'

def b64(value):
    return base64.urlsafe_b64encode(value).rstrip(b'=').decode()

def signature_raw(der):
    # OpenSSL returns ASN.1 DER ECDSA; JWT requires fixed-width R || S.
    if len(der) < 8 or der[0] != 0x30 or der[1] != len(der) - 2:
        raise ValueError('Unexpected ECDSA signature')
    pos, numbers = 2, []
    for _ in range(2):
        if der[pos] != 2:
            raise ValueError('Unexpected ECDSA integer')
        length = der[pos + 1]
        pos += 2
        n = int.from_bytes(der[pos:pos + length], 'big')
        numbers.append(n.to_bytes(32, 'big'))
        pos += length
    if pos != len(der):
        raise ValueError('Unexpected ECDSA signature length')
    return b''.join(numbers)

def token(key_id, issuer, key):
    now = int(time.time())
    head = b64(json.dumps({'alg':'ES256','kid':key_id,'typ':'JWT'}, separators=(',', ':')).encode())
    body = b64(json.dumps({'iss':issuer,'iat':now,'exp':now+1200,'aud':'appstoreconnect-v1'}, separators=(',', ':')).encode())
    message = f'{head}.{body}'
    signed = subprocess.run(['openssl','dgst','-sha256','-sign',str(key)], input=message.encode(), capture_output=True, check=True)
    return message + '.' + b64(signature_raw(signed.stdout))

def get(path, params=None):
    url = API + path
    if params:
        url += '?' + urllib.parse.urlencode(params)
    request = urllib.request.Request(url, headers={'Authorization':'Bearer ' + token(KEY_ID, ISSUER, KEY), 'Accept':'application/json'})
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        raise RuntimeError(f'App Store Connect API HTTP {error.code}: {error.read(2000).decode(errors="replace")}') from error

def run(*args):
    print('+ ' + ' '.join(map(str, args)), flush=True)
    subprocess.run(args, cwd=ROOT, check=True)

def status(version, number, timeout):
    deadline = time.monotonic() + timeout
    last = None
    while time.monotonic() < deadline:
        result = get('builds', {'filter[app]':APP_ID, 'filter[version]':number,
                               'filter[preReleaseVersion.version]':version, 'filter[preReleaseVersion.platform]':'IOS', 'limit':'10'})
        builds = result.get('data', [])
        if len(builds) > 1:
            raise RuntimeError('多个构建匹配，请在 App Store Connect 检查。')
        if builds:
            build = builds[0]
            state = build['attributes']['processingState']
            if state in ('FAILED','INVALID'):
                raise RuntimeError(f'Apple 构建处理失败：{state}')
            if state == 'VALID':
                build_id = build['id']
                details = get(f'builds/{build_id}/buildBetaDetail')['data']['attributes']
                beta = details['internalBuildState']
                groups = get(f'builds/{build_id}/betaGroups', {'limit':'200'}).get('data', [])
                member = any(group['id'] == GROUP_ID for group in groups)
                current = f'处理状态={state}，内部测试状态={beta}，已加入内部测试组={member}'
                if beta == 'IN_BETA_TESTING' and member:
                    print(current + '\n发布成功：内部测试组正在测试。', flush=True)
                    return
                if beta in ('MISSING_EXPORT_COMPLIANCE','PROCESSING_EXCEPTION','EXPIRED'):
                    raise RuntimeError(current)
            else:
                current = 'Apple 处理状态=' + state
        else:
            current = '等待 Apple 创建构建记录（可在 App Store Connect 查看上传记录）'
        if current != last:
            print(current, flush=True)
            last = current
        time.sleep(20)
    raise TimeoutError('等待处理或内部分发超时；请到 App Store Connect 检查，避免重复上传。')

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='仅检查 API 凭据及内部测试组，不上传')
    parser.add_argument('--status', nargs=2, metavar=('VERSION','BUILD'), help='查询已有构建的内部分发状态')
    parser.add_argument('--timeout', type=int, default=1200, help='等待秒数（默认 1200）')
    args = parser.parse_args()
    global KEY_ID, ISSUER, KEY
    config_path = Path.home()/'.config/superpreview/testflight.json'
    config = json.loads(config_path.read_text()) if config_path.is_file() else {}
    KEY_ID = os.environ.get('ASC_KEY_ID') or config.get('key_id', '')
    ISSUER = os.environ.get('ASC_ISSUER_ID') or config.get('issuer_id', '')
    KEY = Path(os.environ.get('ASC_KEY_PATH') or config.get('key_path', '')).expanduser()
    if not KEY_ID or not ISSUER or not KEY.is_file():
        raise RuntimeError('请配置 ~/.config/superpreview/testflight.json，或设置 ASC_KEY_ID、ASC_ISSUER_ID 和 ASC_KEY_PATH。')
    app = get(f'apps/{APP_ID}')['data']
    group = get(f'betaGroups/{GROUP_ID}')['data']
    if app['attributes']['bundleId'] != 'com.yff.YFQuotesDemo' or not group['attributes']['isInternalGroup']:
        raise RuntimeError('App 或测试组与预期不匹配。')
    get('builds', {'filter[app]':APP_ID, 'limit':'1'})
    get(f'betaGroups/{GROUP_ID}/builds', {'limit':'1'})
    print('API 凭据可用，目标：QuoteDemo / 内部测试组。', flush=True)
    if args.check:
        return
    if args.status:
        status(*args.status, args.timeout)
        return
    with (ROOT/'SuperPreview/Info.plist').open('rb') as file:
        info = plistlib.load(file)
    version = info['CFBundleShortVersionString']
    number = str(int(time.time()))
    # A timestamp avoids reusing the previous small sequential build numbers;
    # Apple still rejects a collision if another uploader uses the same second.
    output = Path(tempfile.mkdtemp(prefix='superpreview-testflight-'))
    archive = output/'SuperPreview.xcarchive'
    options = output/'ExportOptions.plist'
    options.write_bytes(plistlib.dumps({'method':'app-store-connect','destination':'upload',
        'signingStyle':'automatic','teamID':TEAM_ID,'manageAppVersionAndBuildNumber':False,'uploadSymbols':True}))
    print(f'构建 {version} ({number})；输出目录：{output}', flush=True)
    run('xcodebuild','archive','-project','SuperPreview.xcodeproj','-scheme','SuperPreview',
        '-configuration','Release','-destination','generic/platform=iOS','-archivePath',str(archive),
        '-allowProvisioningUpdates',f'CURRENT_PROJECT_VERSION={number}')
    archive_info = plistlib.loads((archive/'Products/Applications/SuperPreview.app/Info.plist').read_bytes())
    if archive_info.get('CFBundleVersion') != number or archive_info.get('CFBundleIdentifier') != 'com.yff.YFQuotesDemo':
        raise RuntimeError('归档的构建号或 Bundle ID 与预期不符，已停止上传。')
    run('xcodebuild','-exportArchive','-archivePath',str(archive),'-exportOptionsPlist',str(options),
        '-exportPath',str(output/'upload'),'-allowProvisioningUpdates')
    print('上传完成，等待 Apple 处理及自动分发。', flush=True)
    status(version, number, args.timeout)

if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, ValueError, subprocess.CalledProcessError, OSError, TimeoutError) as e:
        print(f'失败：{e}', file=sys.stderr)
        sys.exit(1)
