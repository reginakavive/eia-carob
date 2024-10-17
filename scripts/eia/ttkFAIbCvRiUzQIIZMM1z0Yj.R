# R script for EiA version of"carob"

## ISSUES
# 1. DOI and much of the metadata is missing
# 2. Data reads are still unstable and user needs to have access
# 3. License is missing (CC-BY)?
# 4. Many valuable variables that need to be integrated still...
# 5. ...

carob_script <- function(path) {
   
   "
	SOME DESCRIPTION GOES HERE...

"
   
   uri <- "ttkFAIbCvRiUzQIIZMM1z0Yj"
   group <- "eia"
   
   meta <- data.frame(
      uri = uri,
      dataset_id = uri,
      publication= NA,
      authors ="Mary Jane; John Doe",
      data_institute ="CARI",
      title = NA,
      group = group,
      license = 'none',
      carob_contributor = 'Cedric Ngakou',
      usecase_code= "USC001",
      usecase_name = 'WA-Rice-ATAFI/MOVE',
      activity = 'addon',
      treatment_vars= "none",
      response_vars= "none",
      project = 'Excellence in Agronomy ',
      data_type = "survey",
      carob_date="2024-10-07",
      notes= "crop yield of rice is too high"
   )
   
   # Manually build path (this can be automated...)
   ff <- carobiner::get_data(uri = uri, path = path, group = group, files = list.files("~/carob-eia/data/raw/eia/Nigeria-ATAFI-AddOn/", full.names = T))
   
   # Retrieve relevant file
   f <- ff[basename(ff) == "EiA_ATAFI CARI_Nigeria_Addon_2022_beingcleaned.xlsx"]
   # Read relevant file
   
   ## Process geo data and some crop managment practices 
   r <- carobiner::read.excel(f,sheet = "data")[-c(1),]
   names(r) <- gsub("_index", "index", names(r))
   d <- data.frame(
      country = r$country,
      on_farm = FALSE,
      is_survey = TRUE,
      adm1=r$admin1,
      adm2=r$admin2,
      location=r$village,
      longitude=as.numeric(r$longitude),
      latitude=as.numeric(r$latitude),
      currency=ifelse(grepl("naira", r$local_currency), "NGN", "ETB") ,
      trial_id =  r$barcodehousehold,
      #technology_use= r$use_case_technology, ## Not a carob variable
      #fertilizer_amount= as.numeric(r$fertiliser_amount),
      fertilizer_type= r$fertiliser_type,
      irrigation_dates= r$Irrigation_months, 
      irregation_source= r$Irrigation_source,
      irrigated= ifelse(grepl("No", r$land_irrigated), FALSE,
                        ifelse(grepl("Yes", r$land_irrigated), TRUE, NA)), 
      #land_prep_method=r$tillage_power,
      index=r$index,
      fertilizer_constraint= r$constraint_fertilizers ## Not a carob variable
   )
   
   ## Adding farmer gender 
   rr <- carobiner::read.excel(f,sheet = "hh_members_details_repeat")[-c(1),]
   names(rr) <- gsub("_index", "index", names(rr))
   rr <- rr[, c("person_gender", "index")]
   colnames(rr) <- c("farmer_gender", "index") 
   d <- merge(d, rr, by= "index", all.x= TRUE) 
   
   ### Processing plot size data 
   r1 <- carobiner::read.excel(f,sheet = "hh_plots_repeat")[-c(1),]
   names(r1) <- gsub("_index", "index", names(r1))
   d1 <- data.frame(
      plot_area= ifelse(grepl("acres", r1$unitland), as.numeric(r1$plot_size)*4047, as.numeric(r1$plot_size)*10000),
      index= r1$index
   )
   
   d <- merge(d, d1, by="index", all.x=TRUE)
   
   ### Processing yield data
   
   r2 <- carobiner::read.excel(f,sheet = "crop_repeat")[-c(1),]
   names(r2) <- gsub("_index", "index", names(r2))
   d2 <- data.frame(
      crop=  tolower(r2$crop_name),
      season=r2$season_grown,
      yield= ifelse(grepl("sacks_100kg", r2$crop_yield_units), as.numeric(r2$crop_yield)*100,
                    ifelse(grepl("sacks_50kg", r2$crop_yield_units), as.numeric(r2$crop_yield)*50,
                    ifelse(grepl("tonnes", r2$crop_yield_units), as.numeric(r2$crop_yield)*1000,
                    ifelse(grepl("other", r2$crop_yield_units), as.numeric(r2$crop_yield)*100,as.numeric(r2$crop_yield))))),
      
      crop_price= ifelse(grepl("price_per_bag_50kg", r2$crop_sold_price_quantityunits), as.numeric(r2$crop_sold_income)/50,
                         ifelse(grepl("100kg|100k", r2$crop_price_quantityunits_other), as.numeric(r2$crop_sold_income)/100,
                         ifelse(grepl("200kg", r2$crop_price_quantityunits_other), as.numeric(r2$crop_sold_income)/200, as.numeric(r2$crop_sold_income)))),
      
      crop_residue_type= r2$crop_residue_use,
      crop_residue_used= ifelse(is.na(r2$crop_residue_use), FALSE, TRUE),
      index=r2$index
      
   ) 
   
   d <- merge(d, d2, by="index", all.x=TRUE)
   
   ## Adding variety, disease, pest and previous crop 
   r3 <- carobiner::read.excel(f,sheet = "plot_information_repeat")[-c(1),]
   names(r3) <- gsub("_index", "index", names(r3))
   d3 <- data.frame(
      row_spacing= as.numeric(r3$distance_lines),
      variety= r3$variety,
      previous_crop= tolower(r3$previous_crop),
      intercrops= r3$inter_crop,
      planting_date= as.character(as.Date(as.numeric(r3$planting_date), origin= "1899-12-30")),
      #land_prep_method= r3$land_prep_activities,
      irrigation_number= as.integer(r3$irrigation_number),
      irrigation_amount= as.numeric(r3$irrigation_amount_mm),
      #pest_species= r3$pest_name,
      #diseases= r3$disease_name,
      index= r3$index
      
   )
   
   d <- merge(d, d3, by="index", all.x=TRUE)
   
   ### Adding organic matter 
   r4 <- carobiner::read.excel(f,sheet = "organic_inputs_details_repeat")[-c(1),]
   names(r4) <- gsub("_index", "index", names(r4))
   d4 <- data.frame(
      OM_amount= ifelse(grepl("bags_of_100kg", r4$organic_input_unit), as.numeric(r4$organic_input_amount)*100,
                        ifelse(grepl("bags_of_50kg", r4$organic_input_unit), as.numeric(r4$organic_input_amount)*50, as.numeric(r4$organic_input_amount))) ,
      OM_type= ifelse(grepl("compost", r4$organic_ids), "compost",
                      ifelse(grepl("manure", r4$organic_id), "farmyard manure",
                      ifelse(grepl("plantBiomass", r4$organic_id), "unknown", "none"))),
      OM_price= r4$organic_input_cost,
      index= r4$index
   )
   d4$OM_used <- ifelse(grepl("none", d4$OM_type), FALSE, TRUE)
   
   d <- merge(d, d4, by="index", all.x=TRUE)
   
   r5 <- carobiner::read.excel(f,sheet = "inorganic_inputs_details_repeat")[-c(1),]
   names(r5) <- gsub("_index", "index", names(r5))
   d5 <- data.frame(
      fertilizer_amount= ifelse(grepl("bags_of_50kg", r5$inorganic_input_unit), as.numeric(r5$inorganic_inputs_amount)*50,
                                ifelse(grepl("bags_of_100kg", r5$inorganic_input_unit), as.numeric(r5$inorganic_inputs_amount)*100, as.numeric(r5$inorganic_inputs_amount))),
      fertilizer_price= r5$inorganic_inputs_costs, ## Total fertilizer cost 
      index= r5$index
      
   )  
   
   d <- merge(d, d5, by=c("index"), all.x=TRUE)
   
   d$yield <- (d$yield/d$plot_area)*10000 #  kg/ha
   d$index <- NULL
   
   ## Fixing fertilizer type 
   p <- carobiner::fix_name(d$fertilizer_type)
   p <- gsub(" ","; ",p)
   p <- gsub("11|15|17|19|20|23|25|23", "", p)
   p <- gsub(NA, "none", p)
   p <- gsub("ammonium_sulphate","DAS", p)
   d$fertilizer_type <- p
   
   ### Fixing crop 
   d$intercrops <- gsub("potatoSweet", "sweetpotato", d$intercrops)
   d$intercrops <- gsub("beansBush", "common bean", d$intercrops)
   d$intercrops <- gsub("bananas", "banana", d$intercrops)
   d$intercrops <- gsub("carrots", "carrot", d$intercrops)
   d$intercrops <- gsub("eggplants", "eggplant", d$intercrops)
   
   d$previous_crop <- gsub("beansclimbing", "common bean", d$previous_crop)
   d$previous_crop <- gsub("treetomato", "tomato", d$previous_crop)
   d$previous_crop <- gsub("cocoyams", "yam", d$previous_crop)
   d$previous_crop <- gsub("carrots", "carrot", d$previous_crop)
   
   # ## Fixing lon and lat
   # d$longitude[grepl("Gastifi", d$location)] <- 11.8305
   # d$latitude[grepl("Gastifi", d$location)] <- 10.6844
   # d$longitude[grepl("Gatasaya", d$location)] <- 8.3022653
   # d$latitude[grepl("Gatasaya", d$location)] <- 12.0514893
   # d$longitude[grepl("Gumusawa", d$location)] <- 8.86320
   # d$latitude[grepl("Gumusawa", d$location)] <- 12.139025 
   
   ### Fixing Irrigation date
   
   d$irrigation_dates <- gsub(" ", "; ", d$irrigation_dates)
   d$irrigation_dates <- gsub("jan", "2023-01", d$irrigation_dates)
   d$irrigation_dates <- gsub("feb", "2023-02", d$irrigation_dates)
   d$irrigation_dates <- gsub("mar", "2022-03", d$irrigation_dates)
   d$irrigation_dates <- gsub("apr", "2022-04", d$irrigation_dates)
   d$irrigation_dates <- gsub("may", "2022-05", d$irrigation_dates)
   d$irrigation_dates <- gsub("jun", "2022-06", d$irrigation_dates)
   d$irrigation_dates <- gsub("jul", "2022-07", d$irrigation_dates)
   d$irrigation_dates <- gsub("aug", "2021-08", d$irrigation_dates)
   d$irrigation_dates <- gsub("sep", "2021-09", d$irrigation_dates)
   d$irrigation_dates <- gsub("oct", "2021-10", d$irrigation_dates)
   d$irrigation_dates <- gsub("nov", "2021-11", d$irrigation_dates)
   d$irrigation_dates <- gsub("dec", "2021-12", d$irrigation_dates)
   
   
   carobiner::write_files(meta, d, path=path)
}

#carob_script(path)
