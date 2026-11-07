#!/home/inmove/.opt/python/bin/python

import sys
import itertools

import requests
from bs4 import BeautifulSoup

word = sys.argv[1]

url = f"https://m.youdao.com/result?lang=en&word={word}"

print(f"Url: {url}")

content = requests.get(url).text

soup = BeautifulSoup(content, "html.parser")

trans = soup.find_all("span", {"class": "trans"})
pos = soup.find_all("span", {"class": "pos"})
wfs_name = soup.find_all("span", {"class": "wfs-name"})
wfs_transformation = soup.find_all("span", {"class": "transformation"})

print("-------------翻译----------------------------")
for content in itertools.zip_longest(pos, trans):
    value = [c.text for c in content if c is not None]
    print(" ".join(value))

phonetic = soup.find_all("span", {"class": "phonetic"})
print("-------------音标----------------------------")
for content in phonetic:
    print(content.text, end = "   ")
print()

print("-------------词性----------------------------")
for content in itertools.zip_longest(wfs_name, wfs_transformation):
    value = [c.text for c in content if c is not None]
    print("\t\t\t".join(value))

phrase = soup.find_all("a", {"class": "point"})
phrase_sen = soup.find_all("p", {"class": "sen-phrase"})
phr_trans = soup.find_all("span", {"class": "phr_trans"})
phrase_sen = phrase_sen + phr_trans
print("-------------短语----------------------------")
for content in itertools.zip_longest(phrase, phrase_sen):
    value = [c.text for c in content if c is not None]
    print("\t\t\t".join(value))
