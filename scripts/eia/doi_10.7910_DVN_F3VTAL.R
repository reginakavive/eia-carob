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
  
  uri <- "doi:10.7910/DVN/F3VTAL"
  group <- "eia"
  ff <- carobiner::get_data(uri, path, group)
  
  dset <- data.frame(
    # Need to fill-in metadata...
    carobiner::read_metadata(uri, path, group, major=1, minor=0),
    # publication = NA,
    # data_institution = 'ABC; IITA',
    # group = group,
    # license = 'Some license here...',
    treatment_vars = 'none',
    response_vars = 'none',
    carob_contributor = 'Eduardo Garcia Bendito',
    # data_citation = '...',
    project = 'Excellence in Agronomy',
    usecase_code= "USC009",
    usecase_name = 'GH-CerLeg-GAIP',
    activity = 'other',
    data_type = "survey",
    carob_date="2024-05-22"
  )
  
  # Survey
  f <- ff[basename(ff) == "EiA Beneficiaries Profile _responses_download.xlsx"]

  # Read relevant file
  ds <- carobiner::read.excel(f, sheet = "Survey Responses")
  
  locs <- data.frame(sapply(as.data.frame(do.call(rbind, strsplit(ds$`Auto Recorded GIS`, ","))), function(x) as.numeric(as.character(x))))
  colnames(locs) <- c("latitude", "longitude", "acc")
  # crop
  crops <- data.frame(sapply(as.data.frame(do.call(rbind, strsplit(ds$`Which crops did you grow last farming season?`, ","))), function(x) tolower(gsub("\\s*\\([^\\)]+\\)", "", x))))
  colnames(crops) <- c("crop", "crop2", "crop3")
  crop <- crops$crop # Assuming first to be the main crop
  # intercrops
  icrop <- data.frame(sapply(as.data.frame(do.call(rbind, strsplit(ds$`If OTHERS in Question, kindly specify`, paste0(c(", ", " and "), collapse = "|")))), function(x) tolower(gsub("\\s*\\([^\\)]+\\)", "", x))))
  icrops <- gsub("NA", "", paste(icrop$V1, ifelse(icrop$V1 != icrop$V2, icrop$V2, NA), sep = "; "))
  icrops <- ifelse(startsWith(icrops , "; "), NA, icrops)
  icrops <- ifelse(endsWith(icrops , "; "), gsub("; ", "", icrops), icrops)
  
  d <- data.frame(
    country = "Ghana",
    hhid = ds$`Record id`,
    is_survey = TRUE,
    on_farm = FALSE,
    location = data.frame(sapply(ds$`Name of community`, function(x) gsub("\\s*\\([^\\)]+\\)", "", x)))[[1]],
    longitude = locs$longitude,
    latitude = locs$latitude,
    geo_uncertainty = locs$acc,
    geo_from_source = TRUE,
    crop = crop,
    intercrops = icrops, # could also be crop_rotation
    land_tenure = ifelse(ds$`Do you own land(s) in the community?` == "(A)Yes", "own", "lease"),
    land_ownedby = data.frame(sapply(ds$`If YES, what type of ownership?`, function(x) gsub("\\s*\\([^\\)]+\\)", "", x)))[[1]],
    cropland_used = data.frame(sapply(ds$`How many acres of the land do you allocate for farming?`, function(x) gsub("\\s*\\([^\\)]+\\)", "", x)))[[1]],
    fertilizer_type = tolower(paste0(na.omit(unique(unlist(strsplit(data.frame(sapply(ds$`What type of fertilizers do you use?`, function(x) gsub("\\s*\\([^\\)]+\\)", "", x)))[[1]], ",", fixed = T)), na.rm = T)), collapse = "; "))
  )
  
  # Fix land area
  d$cropland_used[grep("1-4", d$cropland_used)] <- 2
  d$cropland_used[grep("5-10", d$cropland_used)] <- 7.5
  d$cropland_used[grep("16 and above", d$cropland_used)] <- 16
  d$fertilizer_type <- gsub("npk", "NPK", d$fertilizer_type)
  d$fertilizer_type <- gsub("ammonia", "AN", d$fertilizer_type)
  d$crop <- gsub("soyabeans", "soybean", d$crop)
  d$cropland_used <- as.numeric(d$cropland_used)*0.4 # to Ha
  
  carobiner::write_files(dset, d, path=path)
}
