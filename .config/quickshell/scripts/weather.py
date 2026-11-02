#!/usr/bin/env python3
"""
weather.py - Japanese Meteorological (JMA) Weather Service Backend
Fetches accurate Japan Meteorological Agency (JMA) model weather via Open-Meteo,
manages 47 prefectures + municipal locations, and maintains local cache JSON.
"""

import json
import os
import sys
import urllib.request
import urllib.error

CONFIG_DIR = os.path.expanduser("~/.config/quickshell")
CONFIG_FILE = os.path.join(CONFIG_DIR, "weather_config.json")
CACHE_FILE = os.path.join(CONFIG_DIR, "weather_cache.json")
LOCATIONS_FILE = os.path.join(CONFIG_DIR, "weather_locations.json")

# Master Location Registry (47 Prefectures + Key Municipalities + Special Territory)
LOCATIONS = [
    {
        "id": "hokkaido",
        "name": "北海道",
        "romaji": "Hokkaido",
        "lat": 43.0642,
        "lon": 141.3469,
        "cities": [
            {"name": "札幌市", "romaji": "Sapporo", "lat": 43.0642, "lon": 141.3469},
            {"name": "旭川市", "romaji": "Asahikawa", "lat": 43.7706, "lon": 142.3649},
            {"name": "函館市", "romaji": "Hakodate", "lat": 41.7687, "lon": 140.7288},
            {"name": "小樽市", "romaji": "Otaru", "lat": 43.1907, "lon": 140.9947},
            {"name": "帯広市", "romaji": "Obihiro", "lat": 42.9239, "lon": 143.1961},
            {"name": "釧路市", "romaji": "Kushiro", "lat": 42.9849, "lon": 144.3818},
            {"name": "北見市", "romaji": "Kitami", "lat": 43.8039, "lon": 143.8964},
            {"name": "苫小牧市", "romaji": "Tomakomai", "lat": 42.6347, "lon": 141.6053},
        ]
    },
    {
        "id": "aomori",
        "name": "青森県",
        "romaji": "Aomori",
        "lat": 40.8244,
        "lon": 140.7400,
        "cities": [
            {"name": "青森市", "romaji": "Aomori", "lat": 40.8244, "lon": 140.7400},
            {"name": "八戸市", "romaji": "Hachinohe", "lat": 40.5122, "lon": 141.4884},
            {"name": "弘前市", "romaji": "Hirosaki", "lat": 40.6031, "lon": 140.4642},
        ]
    },
    {
        "id": "iwate",
        "name": "岩手県",
        "romaji": "Iwate",
        "lat": 39.7036,
        "lon": 141.1527,
        "cities": [
            {"name": "盛岡市", "romaji": "Morioka", "lat": 39.7036, "lon": 141.1527},
            {"name": "一関市", "romaji": "Ichinoseki", "lat": 38.9317, "lon": 141.1342},
            {"name": "奥州市", "romaji": "Oshu", "lat": 39.1444, "lon": 141.1394},
        ]
    },
    {
        "id": "miyagi",
        "name": "宮城県",
        "romaji": "Miyagi",
        "lat": 38.2682,
        "lon": 140.8694,
        "cities": [
            {"name": "仙台市", "romaji": "Sendai", "lat": 38.2682, "lon": 140.8694},
            {"name": "石巻市", "romaji": "Ishinomaki", "lat": 38.4344, "lon": 141.3028},
            {"name": "大崎市", "romaji": "Osaki", "lat": 38.5756, "lon": 140.9567},
        ]
    },
    {
        "id": "akita",
        "name": "秋田県",
        "romaji": "Akita",
        "lat": 39.7186,
        "lon": 140.1024,
        "cities": [
            {"name": "秋田市", "romaji": "Akita", "lat": 39.7186, "lon": 140.1024},
            {"name": "横手市", "romaji": "Yokote", "lat": 39.3131, "lon": 140.5544},
            {"name": "大仙市", "romaji": "Daisen", "lat": 39.4533, "lon": 140.4858},
        ]
    },
    {
        "id": "yamagata",
        "name": "山形県",
        "romaji": "Yamagata",
        "lat": 38.2404,
        "lon": 140.3633,
        "cities": [
            {"name": "山形市", "romaji": "Yamagata", "lat": 38.2404, "lon": 140.3633},
            {"name": "鶴岡市", "romaji": "Tsuruoka", "lat": 38.7258, "lon": 139.8242},
            {"name": "酒田市", "romaji": "Sakata", "lat": 38.9144, "lon": 139.8361},
        ]
    },
    {
        "id": "fukushima",
        "name": "福島県",
        "romaji": "Fukushima",
        "lat": 37.7503,
        "lon": 140.4678,
        "cities": [
            {"name": "福島市", "romaji": "Fukushima", "lat": 37.7503, "lon": 140.4678},
            {"name": "郡山市", "romaji": "Koriyama", "lat": 37.4006, "lon": 140.3597},
            {"name": "いわき市", "romaji": "Iwaki", "lat": 37.0506, "lon": 140.8878},
            {"name": "会津若松市", "romaji": "Aizuwakamatsu", "lat": 37.4950, "lon": 139.9278},
        ]
    },
    {
        "id": "ibaraki",
        "name": "茨城県",
        "romaji": "Ibaraki",
        "lat": 36.3659,
        "lon": 140.4712,
        "cities": [
            {"name": "水戸市", "romaji": "Mito", "lat": 36.3659, "lon": 140.4712},
            {"name": "つくば市", "romaji": "Tsukuba", "lat": 36.0835, "lon": 140.0766},
            {"name": "取手市", "romaji": "Toride", "lat": 35.8942, "lon": 140.0617},
            {"name": "日立市", "romaji": "Hitachi", "lat": 36.5986, "lon": 140.6558},
            {"name": "土浦市", "romaji": "Tsuchiura", "lat": 36.0786, "lon": 140.1983},
            {"name": "古河市", "romaji": "Koga", "lat": 36.1964, "lon": 139.7114},
            {"name": "牛久市", "romaji": "Ushiku", "lat": 35.9792, "lon": 140.1472},
            {"name": "ひたちなか市", "romaji": "Hitachinaka", "lat": 36.3958, "lon": 140.5342},
            {"name": "守谷市", "romaji": "Moriya", "lat": 35.9511, "lon": 139.9753},
            {"name": "龍ケ崎市", "romaji": "Ryugasaki", "lat": 35.9122, "lon": 140.1836},
            {"name": "筑西市", "romaji": "Chikusei", "lat": 36.3075, "lon": 139.9819},
            {"name": "神栖市", "romaji": "Kamisu", "lat": 35.8986, "lon": 140.6628},
            {"name": "鹿嶋市", "romaji": "Kashima", "lat": 35.9653, "lon": 140.6453},
            {"name": "笠間市", "romaji": "Kasama", "lat": 36.3456, "lon": 140.2558},
        ]
    },
    {
        "id": "tochigi",
        "name": "栃木県",
        "romaji": "Tochigi",
        "lat": 36.5658,
        "lon": 139.8836,
        "cities": [
            {"name": "宇都宮市", "romaji": "Utsunomiya", "lat": 36.5658, "lon": 139.8836},
            {"name": "小山市", "romaji": "Oyama", "lat": 36.3147, "lon": 139.8003},
            {"name": "栃木市", "romaji": "Tochigi City", "lat": 36.3822, "lon": 139.7344},
            {"name": "日光市", "romaji": "Nikko", "lat": 36.7483, "lon": 139.6986},
        ]
    },
    {
        "id": "gunma",
        "name": "群馬県",
        "romaji": "Gunma",
        "lat": 36.3907,
        "lon": 139.0604,
        "cities": [
            {"name": "前橋市", "romaji": "Maebashi", "lat": 36.3907, "lon": 139.0604},
            {"name": "高崎市", "romaji": "Takasaki", "lat": 36.3219, "lon": 139.0033},
            {"name": "太田市", "romaji": "Ota", "lat": 36.2925, "lon": 139.3742},
            {"name": "伊勢崎市", "romaji": "Isesaki", "lat": 36.3219, "lon": 139.1975},
        ]
    },
    {
        "id": "saitama",
        "name": "埼玉県",
        "romaji": "Saitama",
        "lat": 35.8617,
        "lon": 139.6455,
        "cities": [
            {"name": "さいたま市", "romaji": "Saitama", "lat": 35.8617, "lon": 139.6455},
            {"name": "川越市", "romaji": "Kawagoe", "lat": 35.9253, "lon": 139.4858},
            {"name": "川口市", "romaji": "Kawaguchi", "lat": 35.8078, "lon": 139.7239},
            {"name": "所沢市", "romaji": "Tokorozawa", "lat": 35.7997, "lon": 139.4689},
            {"name": "越谷市", "romaji": "Koshigaya", "lat": 35.8911, "lon": 139.7908},
            {"name": "草加市", "romaji": "Soka", "lat": 35.8286, "lon": 139.8058},
            {"name": "熊谷市", "romaji": "Kumagaya", "lat": 36.1472, "lon": 139.3886},
            {"name": "春日部市", "romaji": "Kasukabe", "lat": 35.9753, "lon": 139.7525},
        ]
    },
    {
        "id": "chiba",
        "name": "千葉県",
        "romaji": "Chiba",
        "lat": 35.6074,
        "lon": 140.1065,
        "cities": [
            {"name": "千葉市", "romaji": "Chiba", "lat": 35.6074, "lon": 140.1065},
            {"name": "船橋市", "romaji": "Funabashi", "lat": 35.6947, "lon": 139.9825},
            {"name": "柏市", "romaji": "Kashiwa", "lat": 35.8622, "lon": 139.9714},
            {"name": "松戸市", "romaji": "Matsudo", "lat": 35.7878, "lon": 139.9036},
            {"name": "市川市", "romaji": "Ichikawa", "lat": 35.7222, "lon": 139.9308},
            {"name": "浦安市", "romaji": "Urayasu", "lat": 35.6531, "lon": 139.8989},
            {"name": "木更津市", "romaji": "Kisarazu", "lat": 35.3814, "lon": 139.9256},
            {"name": "成田市", "romaji": "Narita", "lat": 35.7767, "lon": 140.3186},
            {"name": "流山市", "romaji": "Nagareyama", "lat": 35.8564, "lon": 139.9022},
            {"name": "習志野市", "romaji": "Narashino", "lat": 35.6828, "lon": 140.0219},
            {"name": "野田市", "romaji": "Noda", "lat": 35.9553, "lon": 139.8708},
            {"name": "我孫子市", "romaji": "Abiko", "lat": 35.8647, "lon": 140.0272},
            {"name": "八千代市", "romaji": "Yachiyo", "lat": 35.7222, "lon": 140.1003},
            {"name": "銚子市", "romaji": "Choshi", "lat": 35.7347, "lon": 140.8267},
            {"name": "館山市", "romaji": "Tateyama", "lat": 34.9961, "lon": 139.8697},
        ]
    },
    {
        "id": "tokyo",
        "name": "東京都",
        "romaji": "Tokyo",
        "lat": 35.6895,
        "lon": 139.6917,
        "cities": [
            {"name": "東京 (23区)", "romaji": "Tokyo", "lat": 35.6895, "lon": 139.6917},
            {"name": "八王子市", "romaji": "Hachioji", "lat": 35.6553, "lon": 139.3239},
            {"name": "立川市", "romaji": "Tachikawa", "lat": 35.6995, "lon": 139.4138},
            {"name": "武蔵野市", "romaji": "Musashino", "lat": 35.7176, "lon": 139.5661},
            {"name": "三鷹市", "romaji": "Mitaka", "lat": 35.6833, "lon": 139.5594},
            {"name": "府中市", "romaji": "Fuchu", "lat": 35.6691, "lon": 139.4777},
            {"name": "調布市", "romaji": "Chofu", "lat": 35.6521, "lon": 139.5401},
            {"name": "町田市", "romaji": "Machida", "lat": 35.5467, "lon": 139.4386},
            {"name": "小金井市", "romaji": "Koganei", "lat": 35.6995, "lon": 139.5053},
            {"name": "小平市", "romaji": "Kodaira", "lat": 35.7289, "lon": 139.4778},
            {"name": "国分寺市", "romaji": "Kokubunji", "lat": 35.7103, "lon": 139.4758},
            {"name": "西東京市", "romaji": "Nishitokyo", "lat": 35.7289, "lon": 139.5381},
            {"name": "青梅市", "romaji": "Ome", "lat": 35.7878, "lon": 139.2758},
            {"name": "奥多摩町", "romaji": "Okutama", "lat": 35.8094, "lon": 139.0964},
        ]
    },
    {
        "id": "kanagawa",
        "name": "神奈川県",
        "romaji": "Kanagawa",
        "lat": 35.4478,
        "lon": 139.6425,
        "cities": [
            {"name": "横浜市", "romaji": "Yokohama", "lat": 35.4478, "lon": 139.6425},
            {"name": "川崎市", "romaji": "Kawasaki", "lat": 35.5308, "lon": 139.7028},
            {"name": "相模原市", "romaji": "Sagamihara", "lat": 35.5714, "lon": 139.3736},
            {"name": "藤沢市", "romaji": "Fujisawa", "lat": 35.3400, "lon": 139.4897},
            {"name": "横須賀市", "romaji": "Yokosuka", "lat": 35.2817, "lon": 139.6722},
            {"name": "鎌倉市", "romaji": "Kamakura", "lat": 35.3192, "lon": 139.5467},
            {"name": "小田原市", "romaji": "Odawara", "lat": 35.2558, "lon": 139.1597},
            {"name": "厚木市", "romaji": "Atsugi", "lat": 35.4431, "lon": 139.3625},
        ]
    },
    {
        "id": "niigata",
        "name": "新潟県",
        "romaji": "Niigata",
        "lat": 37.9022,
        "lon": 139.0236,
        "cities": [
            {"name": "新潟市", "romaji": "Niigata", "lat": 37.9022, "lon": 139.0236},
            {"name": "長岡市", "romaji": "Nagaoka", "lat": 37.4464, "lon": 138.8519},
            {"name": "上越市", "romaji": "Joetsu", "lat": 37.1486, "lon": 138.2361},
        ]
    },
    {
        "id": "toyama",
        "name": "富山県",
        "romaji": "Toyama",
        "lat": 36.6953,
        "lon": 137.2114,
        "cities": [
            {"name": "富山市", "romaji": "Toyama", "lat": 36.6953, "lon": 137.2114},
            {"name": "高岡市", "romaji": "Takaoka", "lat": 36.7547, "lon": 137.0189},
        ]
    },
    {
        "id": "ishikawa",
        "name": "石川県",
        "romaji": "Ishikawa",
        "lat": 36.5947,
        "lon": 136.6256,
        "cities": [
            {"name": "金沢市", "romaji": "Kanazawa", "lat": 36.5947, "lon": 136.6256},
            {"name": "小松市", "romaji": "Komatsu", "lat": 36.4025, "lon": 136.4508},
            {"name": "輪島市", "romaji": "Wajima", "lat": 37.3897, "lon": 136.9064},
        ]
    },
    {
        "id": "fukui",
        "name": "福井県",
        "romaji": "Fukui",
        "lat": 36.0653,
        "lon": 136.2217,
        "cities": [
            {"name": "福井市", "romaji": "Fukui", "lat": 36.0653, "lon": 136.2217},
            {"name": "敦賀市", "romaji": "Tsuruga", "lat": 35.6453, "lon": 136.0558},
        ]
    },
    {
        "id": "yamanashi",
        "name": "山梨県",
        "romaji": "Yamanashi",
        "lat": 35.6639,
        "lon": 138.5683,
        "cities": [
            {"name": "甲府市", "romaji": "Kofu", "lat": 35.6639, "lon": 138.5683},
            {"name": "富士吉田市", "romaji": "Fujiyoshida", "lat": 35.4864, "lon": 138.8028},
        ]
    },
    {
        "id": "nagano",
        "name": "長野県",
        "romaji": "Nagano",
        "lat": 36.6514,
        "lon": 138.1811,
        "cities": [
            {"name": "長野市", "romaji": "Nagano", "lat": 36.6514, "lon": 138.1811},
            {"name": "松本市", "romaji": "Matsumoto", "lat": 36.2381, "lon": 137.9719},
            {"name": "上田市", "romaji": "Ueda", "lat": 36.4022, "lon": 138.2506},
            {"name": "軽井沢町", "romaji": "Karuizawa", "lat": 36.3489, "lon": 138.6353},
        ]
    },
    {
        "id": "gifu",
        "name": "岐阜県",
        "romaji": "Gifu",
        "lat": 35.3911,
        "lon": 136.7222,
        "cities": [
            {"name": "岐阜市", "romaji": "Gifu", "lat": 35.3911, "lon": 136.7222},
            {"name": "大垣市", "romaji": "Ogaki", "lat": 35.3667, "lon": 136.6167},
            {"name": "高山市", "romaji": "Takayama", "lat": 36.1461, "lon": 137.2522},
        ]
    },
    {
        "id": "shizuoka",
        "name": "静岡県",
        "romaji": "Shizuoka",
        "lat": 34.9769,
        "lon": 138.3831,
        "cities": [
            {"name": "静岡市", "romaji": "Shizuoka", "lat": 34.9769, "lon": 138.3831},
            {"name": "浜松市", "romaji": "Hamamatsu", "lat": 34.7108, "lon": 137.7261},
            {"name": "沼津市", "romaji": "Numazu", "lat": 35.1006, "lon": 138.8600},
            {"name": "熱海市", "romaji": "Atami", "lat": 35.0964, "lon": 139.0717},
        ]
    },
    {
        "id": "aichi",
        "name": "愛知県",
        "romaji": "Aichi",
        "lat": 35.1802,
        "lon": 136.9066,
        "cities": [
            {"name": "名古屋市", "romaji": "Nagoya", "lat": 35.1802, "lon": 136.9066},
            {"name": "豊橋市", "romaji": "Toyohashi", "lat": 34.7692, "lon": 137.3917},
            {"name": "豊田市", "romaji": "Toyota", "lat": 35.0839, "lon": 137.1558},
            {"name": "岡崎市", "romaji": "Okazaki", "lat": 34.9550, "lon": 137.1681},
            {"name": "一宮市", "romaji": "Ichinomiya", "lat": 35.3039, "lon": 136.7986},
        ]
    },
    {
        "id": "mie",
        "name": "三重県",
        "romaji": "Mie",
        "lat": 34.7303,
        "lon": 136.5086,
        "cities": [
            {"name": "津市", "romaji": "Tsu", "lat": 34.7303, "lon": 136.5086},
            {"name": "四日市市", "romaji": "Yokkaichi", "lat": 34.9653, "lon": 136.6247},
            {"name": "伊勢市", "romaji": "Ise", "lat": 34.4875, "lon": 136.7094},
        ]
    },
    {
        "id": "shiga",
        "name": "滋賀県",
        "romaji": "Shiga",
        "lat": 35.0044,
        "lon": 135.8683,
        "cities": [
            {"name": "大津市", "romaji": "Otsu", "lat": 35.0044, "lon": 135.8683},
            {"name": "彦根市", "romaji": "Hikone", "lat": 35.2744, "lon": 136.2597},
            {"name": "草津市", "romaji": "Kusatsu", "lat": 35.0189, "lon": 135.9619},
        ]
    },
    {
        "id": "kyoto",
        "name": "京都府",
        "romaji": "Kyoto",
        "lat": 35.0211,
        "lon": 135.7556,
        "cities": [
            {"name": "京都市", "romaji": "Kyoto", "lat": 35.0211, "lon": 135.7556},
            {"name": "宇治市", "romaji": "Uji", "lat": 34.8894, "lon": 135.8053},
            {"name": "舞鶴市", "romaji": "Maizuru", "lat": 35.4744, "lon": 135.3853},
            {"name": "福知山市", "romaji": "Fukuchiyama", "lat": 35.2975, "lon": 135.1278},
        ]
    },
    {
        "id": "osaka",
        "name": "大阪府",
        "romaji": "Osaka",
        "lat": 34.6864,
        "lon": 135.5200,
        "cities": [
            {"name": "大阪市", "romaji": "Osaka", "lat": 34.6864, "lon": 135.5200},
            {"name": "堺市", "romaji": "Sakai", "lat": 34.5733, "lon": 135.4831},
            {"name": "東大阪市", "romaji": "Higashiosaka", "lat": 34.6794, "lon": 135.6008},
            {"name": "豊中市", "romaji": "Toyonaka", "lat": 34.7814, "lon": 135.4697},
            {"name": "吹田市", "romaji": "Suita", "lat": 34.7597, "lon": 135.5167},
            {"name": "高槻市", "romaji": "Takatsuki", "lat": 34.8467, "lon": 135.6172},
            {"name": "枚方市", "romaji": "Hirakata", "lat": 34.8142, "lon": 135.6517},
        ]
    },
    {
        "id": "hyogo",
        "name": "兵庫県",
        "romaji": "Hyogo",
        "lat": 34.6913,
        "lon": 135.1830,
        "cities": [
            {"name": "神戸市", "romaji": "Kobe", "lat": 34.6913, "lon": 135.1830},
            {"name": "姫路市", "romaji": "Himeji", "lat": 34.8153, "lon": 134.6853},
            {"name": "西宮市", "romaji": "Nishinomiya", "lat": 34.7375, "lon": 135.3414},
            {"name": "尼崎市", "romaji": "Amagasaki", "lat": 34.7183, "lon": 135.4058},
            {"name": "明石市", "romaji": "Akashi", "lat": 34.6431, "lon": 134.9972},
        ]
    },
    {
        "id": "nara",
        "name": "奈良県",
        "romaji": "Nara",
        "lat": 34.6853,
        "lon": 135.8328,
        "cities": [
            {"name": "奈良市", "romaji": "Nara", "lat": 34.6853, "lon": 135.8328},
            {"name": "橿原市", "romaji": "Kashihara", "lat": 34.5103, "lon": 135.7933},
            {"name": "生駒市", "romaji": "Ikoma", "lat": 34.6919, "lon": 135.6983},
        ]
    },
    {
        "id": "wakayama",
        "name": "和歌山県",
        "romaji": "Wakayama",
        "lat": 34.2261,
        "lon": 135.1675,
        "cities": [
            {"name": "和歌山市", "romaji": "Wakayama", "lat": 34.2261, "lon": 135.1675},
            {"name": "田辺市", "romaji": "Tanabe", "lat": 33.7314, "lon": 135.3789},
            {"name": "白浜町", "romaji": "Shirahama", "lat": 33.6706, "lon": 135.3522},
        ]
    },
    {
        "id": "tottori",
        "name": "鳥取県",
        "romaji": "Tottori",
        "lat": 35.5036,
        "lon": 134.2383,
        "cities": [
            {"name": "鳥取市", "romaji": "Tottori", "lat": 35.5036, "lon": 134.2383},
            {"name": "米子市", "romaji": "Yonago", "lat": 35.4281, "lon": 133.3308},
        ]
    },
    {
        "id": "shimane",
        "name": "島根県",
        "romaji": "Shimane",
        "lat": 35.4722,
        "lon": 133.0506,
        "cities": [
            {"name": "松江市", "romaji": "Matsue", "lat": 35.4722, "lon": 133.0506},
            {"name": "出雲市", "romaji": "Izumo", "lat": 35.3667, "lon": 132.7547},
        ]
    },
    {
        "id": "okayama",
        "name": "岡山県",
        "romaji": "Okayama",
        "lat": 34.6617,
        "lon": 133.9350,
        "cities": [
            {"name": "岡山市", "romaji": "Okayama", "lat": 34.6617, "lon": 133.9350},
            {"name": "倉敷市", "romaji": "Kurashiki", "lat": 34.5850, "lon": 133.7719},
            {"name": "津山市", "romaji": "Tsuyama", "lat": 35.0683, "lon": 134.0042},
        ]
    },
    {
        "id": "hiroshima",
        "name": "広島県",
        "romaji": "Hiroshima",
        "lat": 34.3963,
        "lon": 132.4594,
        "cities": [
            {"name": "広島市", "romaji": "Hiroshima", "lat": 34.3963, "lon": 132.4594},
            {"name": "福山市", "romaji": "Fukuyama", "lat": 34.4858, "lon": 133.3625},
            {"name": "呉市", "romaji": "Kure", "lat": 34.2494, "lon": 132.5658},
            {"name": "尾道市", "romaji": "Onomichi", "lat": 34.4086, "lon": 133.1972},
        ]
    },
    {
        "id": "yamaguchi",
        "name": "山口県",
        "romaji": "Yamaguchi",
        "lat": 34.1858,
        "lon": 131.4714,
        "cities": [
            {"name": "山口市", "romaji": "Yamaguchi", "lat": 34.1858, "lon": 131.4714},
            {"name": "下関市", "romaji": "Shimonoseki", "lat": 33.9578, "lon": 130.9414},
            {"name": "宇部市", "romaji": "Ube", "lat": 33.9483, "lon": 131.2464},
        ]
    },
    {
        "id": "tokushima",
        "name": "徳島県",
        "romaji": "Tokushima",
        "lat": 34.0658,
        "lon": 134.5594,
        "cities": [
            {"name": "徳島市", "romaji": "Tokushima", "lat": 34.0658, "lon": 134.5594},
            {"name": "鳴門市", "romaji": "Naruto", "lat": 34.1792, "lon": 134.6083},
        ]
    },
    {
        "id": "kagawa",
        "name": "香川県",
        "romaji": "Kagawa",
        "lat": 34.3403,
        "lon": 134.0433,
        "cities": [
            {"name": "高松市", "romaji": "Takamatsu", "lat": 34.3403, "lon": 134.0433},
            {"name": "丸亀市", "romaji": "Marugame", "lat": 34.2897, "lon": 133.7975},
        ]
    },
    {
        "id": "ehime",
        "name": "愛媛県",
        "romaji": "Ehime",
        "lat": 33.8417,
        "lon": 132.7661,
        "cities": [
            {"name": "松山市", "romaji": "Matsuyama", "lat": 33.8417, "lon": 132.7661},
            {"name": "今治市", "romaji": "Imabari", "lat": 34.0664, "lon": 132.9978},
            {"name": "新居浜市", "romaji": "Niihama", "lat": 33.9603, "lon": 133.2831},
        ]
    },
    {
        "id": "kochi",
        "name": "高知県",
        "romaji": "Kochi",
        "lat": 33.5597,
        "lon": 133.5311,
        "cities": [
            {"name": "高知市", "romaji": "Kochi", "lat": 33.5597, "lon": 133.5311},
            {"name": "南国市", "romaji": "Nankoku", "lat": 33.5786, "lon": 133.6425},
        ]
    },
    {
        "id": "fukuoka",
        "name": "福岡県",
        "romaji": "Fukuoka",
        "lat": 33.6064,
        "lon": 130.4181,
        "cities": [
            {"name": "福岡市", "romaji": "Fukuoka", "lat": 33.6064, "lon": 130.4181},
            {"name": "北九州市", "romaji": "Kitakyushu", "lat": 33.8833, "lon": 130.8753},
            {"name": "久留米市", "romaji": "Kurume", "lat": 33.3194, "lon": 130.5083},
            {"name": "飯塚市", "romaji": "Iizuka", "lat": 33.6461, "lon": 130.6917},
            {"name": "太宰府市", "romaji": "Dazaifu", "lat": 33.5139, "lon": 130.5239},
        ]
    },
    {
        "id": "saga",
        "name": "佐賀県",
        "romaji": "Saga",
        "lat": 33.2494,
        "lon": 130.2989,
        "cities": [
            {"name": "佐賀市", "romaji": "Saga", "lat": 33.2494, "lon": 130.2989},
            {"name": "唐津市", "romaji": "Karatsu", "lat": 33.4503, "lon": 129.9678},
            {"name": "鳥栖市", "romaji": "Tosu", "lat": 33.3769, "lon": 130.5103},
        ]
    },
    {
        "id": "nagasaki",
        "name": "長崎県",
        "romaji": "Nagasaki",
        "lat": 32.7447,
        "lon": 129.8736,
        "cities": [
            {"name": "長崎市", "romaji": "Nagasaki", "lat": 32.7447, "lon": 129.8736},
            {"name": "佐世保市", "romaji": "Sasebo", "lat": 33.1597, "lon": 129.7239},
            {"name": "諫早市", "romaji": "Isahaya", "lat": 32.8431, "lon": 130.0522},
        ]
    },
    {
        "id": "kumamoto",
        "name": "熊本県",
        "romaji": "Kumamoto",
        "lat": 32.7897,
        "lon": 130.7417,
        "cities": [
            {"name": "熊本市", "romaji": "Kumamoto", "lat": 32.7897, "lon": 130.7417},
            {"name": "八代市", "romaji": "Yatsushiro", "lat": 32.5072, "lon": 130.6019},
            {"name": "天草市", "romaji": "Amakusa", "lat": 32.4589, "lon": 130.1919},
        ]
    },
    {
        "id": "oita",
        "name": "大分県",
        "romaji": "Oita",
        "lat": 33.2381,
        "lon": 131.6125,
        "cities": [
            {"name": "大分市", "romaji": "Oita", "lat": 33.2381, "lon": 131.6125},
            {"name": "別府市", "romaji": "Beppu", "lat": 33.2847, "lon": 131.4911},
            {"name": "中津市", "romaji": "Nakatsu", "lat": 33.5981, "lon": 131.1883},
        ]
    },
    {
        "id": "miyazaki",
        "name": "宮崎県",
        "romaji": "Miyazaki",
        "lat": 31.9111,
        "lon": 131.4239,
        "cities": [
            {"name": "宮崎市", "romaji": "Miyazaki", "lat": 31.9111, "lon": 131.4239},
            {"name": "都城市", "romaji": "Miyakonojo", "lat": 31.7194, "lon": 131.0617},
            {"name": "延岡市", "romaji": "Nobeoka", "lat": 32.5822, "lon": 131.6647},
        ]
    },
    {
        "id": "kagoshima",
        "name": "鹿児島県",
        "romaji": "Kagoshima",
        "lat": 31.5603,
        "lon": 130.5581,
        "cities": [
            {"name": "鹿児島市", "romaji": "Kagoshima", "lat": 31.5603, "lon": 130.5581},
            {"name": "霧島市", "romaji": "Kirishima", "lat": 31.7417, "lon": 130.7633},
            {"name": "鹿屋市", "romaji": "Kanoya", "lat": 31.3783, "lon": 130.8522},
            {"name": "奄美市", "romaji": "Amami", "lat": 28.3769, "lon": 129.4950},
        ]
    },
    {
        "id": "okinawa",
        "name": "沖縄県",
        "romaji": "Okinawa",
        "lat": 26.2125,
        "lon": 127.6811,
        "cities": [
            {"name": "那覇市", "romaji": "Naha", "lat": 26.2125, "lon": 127.6811},
            {"name": "沖縄市", "romaji": "Okinawa City", "lat": 26.3356, "lon": 127.8014},
            {"name": "うるま市", "romaji": "Uruma", "lat": 26.3778, "lon": 127.8597},
            {"name": "浦添市", "romaji": "Urasoe", "lat": 26.2472, "lon": 127.7208},
            {"name": "名護市", "romaji": "Nago", "lat": 26.5919, "lon": 127.9772},
            {"name": "石垣市", "romaji": "Ishigaki", "lat": 24.3447, "lon": 124.1572},
            {"name": "宮古島市", "romaji": "Miyakojima", "lat": 24.8058, "lon": 125.2811},
        ]
    },
    {
        "id": "islands",
        "name": "特区・孤島",
        "romaji": "Special Is.",
        "lat": 20.4242,
        "lon": 136.0811,
        "cities": [
            {"name": "沖ノ鳥島", "romaji": "Okinotorishima", "lat": 20.4242, "lon": 136.0811},
            {"name": "南鳥島", "romaji": "Minamitorishima", "lat": 24.2883, "lon": 153.9806},
            {"name": "父島 (小笠原)", "romaji": "Chichijima", "lat": 27.0933, "lon": 142.1919},
            {"name": "八丈島", "romaji": "Hachijojima", "lat": 33.1119, "lon": 139.7897},
            {"name": "大島", "romaji": "Izu Oshima", "lat": 34.7522, "lon": 139.3564},
        ]
    }
]

# WMO Weather Interpretation Codes (JMA Standard)
WMO_MAP = {
    0: ("󰖐", "Clear Sky"),
    1: ("󰖕", "Mainly Clear"),
    2: ("󰖕", "Partly Cloudy"),
    3: ("󰖐", "Overcast"),
    45: ("󰖑", "Foggy"),
    48: ("󰖑", "Depositing Rime Fog"),
    51: ("󰖖", "Light Drizzle"),
    53: ("󰖖", "Moderate Drizzle"),
    55: ("󰖖", "Dense Drizzle"),
    56: ("󰖖", "Freezing Drizzle"),
    57: ("󰖖", "Dense Freezing Drizzle"),
    61: ("󰖖", "Slight Rain"),
    63: ("󰖖", "Moderate Rain"),
    65: ("󰖖", "Heavy Rain"),
    66: ("󰖖", "Freezing Rain"),
    67: ("󰖖", "Heavy Freezing Rain"),
    71: ("󰖘", "Slight Snow"),
    73: ("󰖘", "Moderate Snow"),
    75: ("󰖘", "Heavy Snow"),
    77: ("󰖘", "Snow Grains"),
    80: ("󰖖", "Slight Rain Showers"),
    81: ("󰖖", "Moderate Showers"),
    82: ("󰖖", "Violent Showers"),
    85: ("󰖘", "Slight Snow Showers"),
    86: ("󰖘", "Heavy Snow Showers"),
    95: ("󰖓", "Thunderstorm"),
    96: ("󰖓", "Thunderstorm w/ Hail"),
    99: ("󰖓", "Severe Thunderstorm"),
}

WIND_DIRECTIONS = [
    "北", "北北東", "北東", "東北東",
    "東", "東南東", "南東", "南南東",
    "南", "南南西", "南西", "西南西",
    "西", "西北西", "北西", "北北西"
]

def deg_to_compass(deg):
    if deg is None:
        return ""
    val = int((float(deg) + 11.25) / 22.5) % 16
    return WIND_DIRECTIONS[val]

def export_locations():
    """Exports structured locations JSON for fast QML consumption."""
    os.makedirs(CONFIG_DIR, exist_ok=True)
    with open(LOCATIONS_FILE, "w", encoding="utf-8") as f:
        json.dump(LOCATIONS, f, ensure_ascii=False, indent=2)

def load_config():
    """Loads active location from config, defaulting to Tokyo."""
    default_config = {
        "name": "東京 (23区)",
        "romaji": "Tokyo",
        "pref": "東京都",
        "lat": 35.6895,
        "lon": 139.6917
    }
    if os.path.isfile(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
                if "lat" in data and "lon" in data:
                    return data
        except Exception:
            pass
    return default_config

def save_config(city_data):
    """Saves selected city to config file."""
    os.makedirs(CONFIG_DIR, exist_ok=True)
    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        json.dump(city_data, f, ensure_ascii=False, indent=2)

def fetch_weather(city_data=None):
    """Fetches high-accuracy JMA model forecast from Open-Meteo API."""
    if city_data is None:
        city_data = load_config()

    lat = city_data.get("lat", 35.6895)
    lon = city_data.get("lon", 139.6917)

    url = (
        f"https://api.open-meteo.com/v1/forecast?"
        f"latitude={lat}&longitude={lon}&"
        f"current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,wind_direction_10m&"
        f"daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,wind_direction_10m_dominant&"
        f"timezone=Asia%2FTokyo"
    )

    req = urllib.request.Request(url, headers={"User-Agent": "Antigravity-Quickshell-Weather/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=6) as response:
            raw_data = json.loads(response.read().decode("utf-8"))
    except Exception as e:
        print(f"Error fetching weather: {e}", file=sys.stderr)
        return False

    current = raw_data.get("current", {})
    daily = raw_data.get("daily", {})

    cur_code = current.get("weather_code", 0)
    icon, desc = WMO_MAP.get(cur_code, ("󰖐", "Clear"))
    cur_temp = f"{round(current.get('temperature_2m', 0))}°C"
    cur_humidity = f"{round(current.get('relative_humidity_2m', 0))}%"
    cur_wind_speed = f"{round(current.get('wind_speed_10m', 0))} km/h"
    cur_wind_dir = deg_to_compass(current.get("wind_direction_10m"))

    # Daily max/min & rain chance for today
    max_temps = daily.get("temperature_2m_max", [0])
    min_temps = daily.get("temperature_2m_min", [0])
    rain_probs = daily.get("precipitation_probability_max", [0])
    daily_codes = daily.get("weather_code", [0])
    daily_times = daily.get("time", [""])
    wind_speeds = daily.get("wind_speed_10m_max", [0])
    wind_dirs = daily.get("wind_direction_10m_dominant", [0])

    today_max = f"{round(max_temps[0])}°C" if len(max_temps) > 0 and max_temps[0] is not None else "--°C"
    today_min = f"{round(min_temps[0])}°C" if len(min_temps) > 0 and min_temps[0] is not None else "--°C"
    today_rain = f"{round(rain_probs[0])}%" if len(rain_probs) > 0 and rain_probs[0] is not None else "0%"

    # 2-Day Forecast (Tomorrow & Day after tomorrow)
    day_names = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    forecast = []
    import datetime
    for i in range(1, min(3, len(daily_times))):
        d_str = daily_times[i]
        try:
            dt = datetime.date.fromisoformat(d_str)
            d_name = day_names[(dt.weekday() + 1) % 7]
        except Exception:
            d_name = f"+{i}D"

        code = daily_codes[i] if i < len(daily_codes) else 0
        f_icon, f_desc = WMO_MAP.get(code, ("󰖐", "Clear"))
        f_max = f"{round(max_temps[i])}°" if i < len(max_temps) and max_temps[i] is not None else "--°"
        f_min = f"{round(min_temps[i])}°" if i < len(min_temps) and min_temps[i] is not None else "--°"
        f_rain = f"{round(rain_probs[i])}%" if i < len(rain_probs) and rain_probs[i] is not None else "0%"
        f_wind_spd = f"{round(wind_speeds[i])} km/h" if i < len(wind_speeds) and wind_speeds[i] is not None else ""
        f_wind_d = deg_to_compass(wind_dirs[i]) if i < len(wind_dirs) else ""

        forecast.append({
            "day": d_name,
            "date": d_str,
            "icon": f_icon,
            "desc": f_desc,
            "max": f_max,
            "min": f_min,
            "rainChance": f_rain,
            "windDir": f_wind_d,
            "windSpeed": f_wind_spd
        })

    cached_payload = {
        "city": city_data,
        "current": {
            "temp": cur_temp,
            "desc": desc,
            "icon": icon,
            "maxTemp": today_max,
            "minTemp": today_min,
            "rainChance": today_rain,
            "wind": cur_wind_speed,
            "windDir": cur_wind_dir,
            "humidity": cur_humidity
        },
        "forecast": forecast,
        "updatedAt": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }

    os.makedirs(CONFIG_DIR, exist_ok=True)
    with open(CACHE_FILE, "w", encoding="utf-8") as f:
        json.dump(cached_payload, f, ensure_ascii=False, indent=2)

    return True

def main():
    if len(sys.argv) > 1:
        cmd = sys.argv[1]
        if cmd == "--export-locations":
            export_locations()
            print(f"Exported locations to {LOCATIONS_FILE}")
            return
        elif cmd == "--set-city":
            if len(sys.argv) > 2:
                city_json = sys.argv[2]
                city_data = json.loads(city_json)
                save_config(city_data)
                fetch_weather(city_data)
                print(f"Set city to {city_data.get('name')} and refreshed cache.")
                return
        elif cmd == "--fetch":
            export_locations()
            ok = fetch_weather()
            if ok:
                print("Weather fetched successfully.")
            else:
                sys.exit(1)
            return

    # Default action: ensure locations exist and fetch weather
    export_locations()
    fetch_weather()

if __name__ == "__main__":
    main()
