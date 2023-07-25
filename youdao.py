#!/home/inmove/miniconda3/envs/py3.11/bin/python

import uuid
import requests
import hashlib
import time
import pprint
import sys
import os

YOUDAO_URL = 'https://openapi.youdao.com/api'
APP_KEY = os.environ.get("YOU_DAO_APP_KEY")
APP_SECRET = os.environ.get("YOU_DAO_APP_SECRET")


class ColorPrinter:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

    BLACK_FONT_C = "\033[30m"
    RED_FONT_C = "\033[31m"
    GREEN_FONT_C = "\033[32m"
    YELLOW_FONT_C = "\033[33m"
    DARK_BLUE_FONT_C = "\033[34m"
    PINK_FONT_C = "\033[35m"
    LIGHT_BLUE_FONT_C = "\033[36m"
    LIGHT_GREY_FONT_C = "\033[90m"
    ORIGIN_FONT_C = "\033[91m"

    @classmethod
    def color_value(cls, color, value):
        return color + str(value) + cls.ENDC

    @classmethod
    def red_value(cls, value):
        return cls.color_value(cls.RED_FONT_C, value)

    @classmethod
    def green_value(cls, value):
        return cls.color_value(cls.GREEN_FONT_C, value)


def encrypt(signStr):
    hash_algorithm = hashlib.sha256()
    hash_algorithm.update(signStr.encode('utf-8'))
    return hash_algorithm.hexdigest()


def truncate(q):
    if q is None:
        return None
    size = len(q)
    return q if size <= 20 else q[0:10] + str(size) + q[size - 10:size]


def do_request(data):
    headers = {'Content-Type': 'application/x-www-form-urlencoded'}
    return requests.post(YOUDAO_URL, data=data, headers=headers)


def connect():
    if '' in (APP_KEY, APP_SECRET) or None in (APP_KEY, APP_SECRET):
        raise Exception("请设置有道YOU_DAO_APP_KEY,YOU_DAO_APP_SECRET到环境变量")
    if len(sys.argv) == 1:
        raise Exception("请输入要查询的内容: tl xxx")
    q = " ".join(sys.argv[1:])

    salt = str(uuid.uuid1())
    curtime = str(int(time.time()))
    signStr = APP_KEY + truncate(q) + salt + curtime + APP_SECRET
    data = {
        'from': 'en',
        'to': 'zh-CHS',
        'signType': 'v3',
        'curtime': curtime,
        'sign': encrypt(signStr),
        'appKey': APP_KEY,
        'q': q,
        'salt': salt,
    }
    response = do_request(data)
    result = response.json()
    pp = pprint.PrettyPrinter(indent=2)
    pp.pprint(result)
    print("--------------------------------------------------------\n")
    display(result)

def display(result):
    display_value = []
    display_value.append(
        f"    {ColorPrinter.red_value(result.get('query'))}"
    )
    if 'basic' in result:
        basic = result.get('basic')

        explains = basic.get("explains")
        if explains:
            display_value.append('\n\t名词解释: ')
            for explain in explains:
                display_value.append(
                    f"\t\t - {ColorPrinter.color_value(ColorPrinter.RED_FONT_C, explain)}"
                )

        if basic.get("wfs"):
            display_value.append('\n\t词性说明')
            wfs = [
                f"{wf.get('wf').get('name')} - {wf.get('wf').get('value')}"
                for wf in basic.get("wfs", [])
            ]
            for wf in wfs:
                display_value.append(
                    f"\t\t - {ColorPrinter.color_value(ColorPrinter.GREEN_FONT_C, wf)}"
                )

    if 'web' in result:
        display_value.append('\n\t网络词意')
        web = [f"{web.get('key')} - {web.get('value')}" for web in result.get("web", [])]
        for w in web:
            display_value.append(
                f"\t\t - {ColorPrinter.color_value(ColorPrinter.LIGHT_BLUE_FONT_C,w)}"
            )

    if len(display_value) == 1:
        print(ColorPrinter.red_value("未查询到相关的信息"))

    for value in display_value:
        print(value)


if __name__ == '__main__':
    connect()
