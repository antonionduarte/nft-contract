import json

def convert_to_json(path, output_name):
	file = open(path, "r");
	lines = file.readlines()
	file.close()
	processed_lines = []

	for line in lines:
		processed_line = line.strip()
		processed_lines.append(processed_line)
	
	json_output = json.dumps({ "addresses": processed_lines })
	output = open(output_name, "w")
	output.write(json_output)
	output.close()

def main():
	convert_to_json("ballers.txt", "ballers.json")
	convert_to_json("stacked.txt", "stacked.json")
	convert_to_json("community.txt", "community.json")

main()

