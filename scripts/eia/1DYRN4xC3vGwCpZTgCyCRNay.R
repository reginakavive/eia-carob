# R script for EiA version of"carob"

## ISSUES
# 1. DOI and much of the metadata is missing
# 2. License is missing (CC-BY)?
# 3. Many valuable variables that need to be integrated still...
# 4. ...

carob_script <- function(path) {
   
   "
	SOME DESCRIPTION GOES HERE...

"
   
   
   uri <- "1DYRN4xC3vGwCpZTgCyCRNay"
   group <- "eia"
   
   meta <- data.frame(
      # Need to fill-in metadata...
      # carobiner::read_metadata(uri, path, group, major=2, minor=0),
      uri = uri,
      dataset_id = uri,
      data_institute = "ICRISAT",
      authors = "Gizaw Desta",
      title = "Fertilizer Ethiopia Use Case Validations 2022",
      description = "Data for the use case validaton of fertilizer landscape recommendations for Ethiopia 2021",
      group = group,
      license = 'Some license here...',
      carob_contributor = 'Eduardo Garcia Bendito',
      data_citation = '...',
      project = 'Excellence in Agronomy',
      usecase_code= "USC007",
      usecase_name = "ET-HighMix-Gvt ETH",
      activity = "validation",
      treatment_vars = "N_fertilizer; P_fertilizer; variety_type; planting_method; landscape_position; herbicide_used; insecticide_used",
      response_vars = "yield; residue_yield",
      data_type = "on-farm experiment", 
      carob_date="2024-05-30"
   )
   
   # Manually build path (this can be automated...)
   ff <- carobiner::get_data(uri = uri, path = path, group = group, files = list.files("~/carob-eia/data/raw/eia/Ethiopia-Fertilizer-Validation/", full.names = T))
   
   # Retrieve relevant file
   f <- ff[basename(ff) == "ICRISAT_EIA_FertEth_ValidationData.xlsx"]
   
   # Read relevant file
   r <- carobiner::read.excel(f)
   
   # Build initial DF ... Start from here
   d <- data.frame(
      country = "Ethiopia",
      yield_part = "grain",	
      on_farm = TRUE,
      is_survey = FALSE,
      irrigated = FALSE,
      adm1=r$District,
      adm2=r$Kebele,
      trial_id = r$`Farmers code`, # Using HHID as trial_id
      latitude =r$Latitude,
      longitude=r$Longitude,
      elevation=r$Altitude,
      geo_from_source = TRUE,
      planting_date = as.character(r$Year),
      crop = tolower(r$crop),
      variety = r$`Crop variety name`,
      variety_type = r$`Variety maturity`, # Not landrace but maturity category...
      treatment=r$Treatment,
      fertilizer_type = "urea; NPK",
      N_fertilizer=r$`N_ kg/ha`,
      P_fertilizer=r$`P_kg/ha`,
      K_fertilizer= 0, ##  
      # How to convert weight to plant?
      # seed_density = r$`Seed rate (kg/ha)`,
      planting_method = tolower(r$`Planting method`),
      landscape_position = r$Landscape,
      pest_severity = r$`Pest and disease occurrance`, #Severity was assumed to be Low or Medium
      land_prep_method = tolower(r$`Tillage management`),
      herbicide_used = ifelse(r$`Herbicide application frequency` != 0, TRUE, FALSE),
      herbicide_times = as.integer(r$`Herbicide application frequency`),
      insecticide_used = ifelse(r$`Pesticides  (Liter or KG)/ha` != 0, TRUE, FALSE),
      insecticide_amount = r$`Pesticides  (Liter or KG)/ha`,
      weeding_times = as.integer(r$`Hand weeding frequency`),
      crop_rotation = NA,
      soil_color = r$`soil color`,
      soil_quality = r$`Soil fertility`,
      previous_crop = tolower(r$`Crop rotation in past 1 year`),
      plot_area = r$`Plot size (m2)`, # in m2
      yield = r$`Grain yield (kg/ha)`,
      fwy_residue = r$`Straw yield (kg/ha)`, #The straw weight is assumed to be the residue of the yield
      crop_price = r$`Price of grain per 100 kg (ETH Birr)` + r$`Price of straw per 100kg (ETH Birr)`, # Prices in Ethiopian Birr (ETB) per 100kg for grain and straw
      fertilizer_price = as.character(r$`Price of fertilizerz PER 100KG`), 
      currency = "ETB"
   )
   
   ##CN
   ## Fill crop rotation using crop system
   d$crop_system <- r$`Crop system`
   d$crop_rotation[grep("Fababean", d$crop_system)] <- c("barley", "faba bean", "wheat")
   d$crop_rotation[grep("Barley", d$crop_system)] <- c("barley")
   d$crop_rotation[grep("Wheat", d$crop_system)] <- NA
   d$crop_rotation[grep("Mixed",d$crop_system)] <- NA
   
   d$crop_system <- NULL
   
   d$pest_severity[grep("low", d$pest_severity)] <- c("Low") #Change "low" to "Low"
   
   ## Fix name 
   d$planting_method[grep("broadcast", d$planting_method)]  <- "broadcasting"
   d$land_prep_method[grep("conventional oxen tillage", d$land_prep_method)]  <- "conventional"
   
   ## Fix longitude and latitude 
   d$longitude[grep("Goshebado", d$adm2)] <- 39.44261
   d$latitude[grep("Goshebado", d$adm2)] <- 9.742694
   
   ## Fix crop price and fertilizer price 
   d$crop_price <- d$crop_price/100 ## ETB/Kg
   
   carobiner::write_files(meta, d, path=path)
}
