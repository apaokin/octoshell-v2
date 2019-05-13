# Hardware
Engine is developed to  administer supercomputer center hardware, its status.
## API
Devices can be created or updated via WEB API.
	You have to specify secret named **hardware_api** and send JSON to /hardware/admin/items/json_update in this format:

	{
		"password": "test12345", # password specified in hardware_api secret
		"language": "en", # Chosen language affects validation. You should specify mandatory attributes (e.g. name) for your devices.
		"data":[
			{
				"id":4, # specify id to edit existing device. Don't specify him to create a new device.
				"name_ru":"", # unnecessary
				"name_en":"Switch 1", # name en is required for english language!
				"description_ru":"",  # unnecessary
				"description_en":"",  # unnecessary
				"kind_id":2,  # id of device kind
				"state":{
					"state_id" : 9, transit to state with id = 9
					"reason_ru": "Я хочу", # unnecessary
					"description_ru": "Договор номер такой-то такой-то",  # unnecessary
					"description_en": ""  # unnecessary
				}
			},
			{
				"name_en": "created_via_json6", # name en is required for english language!
				"kind_id": "2", #  # id of device kind
				"state":{
					"state_id" : 8, # transit to state with id = 8
					"reason_ru": "Я хочу", # unnecessary
					"description_ru": "Договор номер такой-то такой-то", # unnecessary
					"description_en": "" # unnecessary
				}
			}
		]
	}
