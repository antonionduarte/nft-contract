from cgi import test
import json
from copy import deepcopy
from lib2to3.pgen2.tokenize import generate_tokens
import os

BASE_IMAGE_URL = "ipfs://cid/"
BASE_NAME = "test"
BASE_DESCRIPTION = "it's honestly simply a test"

TOKEN_AMOUNT = 6666 

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
		item_json["image"] = BASE_IMAGE_URL + str(i) + ".gif"
		json_data = json.dumps(item_json)

		file_name = str(i) + ".json"
		complete_name = os.path.join('./generated-metadata/', file_name)

		f = open(complete_name, "x")
		f.write(json_data)

generateJSON()