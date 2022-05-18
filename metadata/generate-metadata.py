from cgi import test
import json
from copy import deepcopy
from lib2to3.pgen2.tokenize import generate_tokens
import os

BASE_IMAGE_URL = "ipfs://QmdCfZDb7S9W88SGKWGqyLsQcWxTe7YtgNhSuqpJVnrRiS/pre-reveal.gif"
BASE_NAME = "MoneyBags"
BASE_DESCRIPTION = "Money Bags Pre-Reveal"

TOKEN_AMOUNT = 5555 

PATH = "./generate-metadata/"

BASE_JSON = {
	"name": BASE_NAME,
	"description": BASE_DESCRIPTION,
	"image": "",
	"attributes": []
}

def generateJSON():
	for i in range (0, TOKEN_AMOUNT):
		item_json = deepcopy(BASE_JSON)
		item_json["image"] = BASE_IMAGE_URL
		item_json["name"] = BASE_NAME + " #" + str(i)
		json_data = json.dumps(item_json)

		file_name = str(i)
		complete_name = os.path.join('./moneybags-prereveal/', file_name)

		f = open(complete_name, "x")
		f.write(json_data)

generateJSON()
