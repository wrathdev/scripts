#!/usr/bin/env python3

__author__ = "Ashutosh Varma"
__copyright__ = "Copyright 2019, Ashutosh Varma"
__license__ = "MIT"


import sys
import re
import time
import argparse

#Check for python version.
#f-strings are introduced in 3.6.
if not (sys.version_info.major >= 3 and sys.version_info.minor >= 6):
    print("ERROR: Script is only compatible with python 3.6 or higher")
    exit(-1)

try:
    import requests
except ModuleNotFoundError:
    print("Error: Cannot import requests module.")
    exit(-2)


# Constants
headers = {
    "Host": "172.16.16.16:8090",
    "Connection": "keep-alive",
    "Content-Length": "83",
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.56 Safari/537.36",
    "Content-Type": "application/x-www-form-urlencoded",
    "Accept": "*/*",
    "Origin": "http://172.16.16.16:8090",
    "Referer": "http://172.16.16.16:8090/httpclient.html",
    "Accept-Encoding": "gzip, deflate",
    "Accept-Language": "en-IN,en-US;q=0.9,en;q=0.8"
}

login_url = "http://172.16.16.16:8090/login.xml"
# logout_url = "http://172.16.16.16:8090/logout.xml"


xml_search_str = {
    "sucess": "LIVE",
    "failed": "Login failed. Invalid user name/password",
    "max_limit": "You have reached the maximum login limit",
    "logout": "signed out",
    "connection_problem": "Unable to access auth service"
}


# Utilts
def time_milli() -> int:
    return int(time.time() * 1000)


def scrap_xml_msg(xml: str) -> str:
    re_msg = re.compile(r"(?<=<message><!\[CDATA\[)(.+?)(?=]]><\/message>)")
    m = re_msg.search(xml)
    if m:
        return m.string
    else:
        return ""


def req_login(username: str, password: str, producttype: int = 0) -> requests.Response:
    payload = {
        'username': username,
        "a": time_milli(),
        "mode": 191,
        "producttype": producttype
    }
    return requests.post(login_url, data=payload, headers=headers)


def login(username: str, password: str):
    try:
        resp = req_login(username, password)
    except:
        print("Error: Cannot connect to the login portal. Check network connection.")
        print("Info: Your MAC might be blacklisted, so try changing that.")
        exit(1)
    else:
        if resp.status_code == 200:
            response_xml = resp.text
            # Check for sucessful login
            if xml_search_str['sucess'] in response_xml:
                print("SUCESS: Sign IN Sucessful.")
                exit(0)
            elif xml_search_str['failed'] in response_xml:
                print(f"ERROR: {xml_search_str['failed']}")
                exit(2)
            elif xml_search_str['max_limit'] in response_xml:
                print(f"ERROR: {xml_search_str['max_limit']}")
                exit(3)
            elif xml_search_str['connection_problem'] in response_xml:
                print(f"ERROR: {xml_search_str['connection_problem']}")
                exit(4)
            else:
                msg = scrap_xml_msg(response_xml)
                if msg:
                    print(f"ERROR: {msg}")
                else:
                    print("ERROR: Unkown Error Occurred." + "\n" +
                          "ResponseXML:-" + "\n" + response_xml)
                exit(5)


def parseargs():
    parser = argparse.ArgumentParser(
        description="Python Script to login to GGSIPU college network.")
    parser.add_argument(
        "username", type=str, help="Your username. Usually it is your 11 digit roll no.")
    parser.add_argument("password", type=str, help="Pssaword to login with.")
    parser.add_argument("-v", "--verbose", action="store_true")

    return parser.parse_args()


def main():
    args = parseargs()
    login(args.username, args.password)


if __name__ == "__main__":
    main()
