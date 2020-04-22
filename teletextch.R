#!/usr/bin/Rscript:x
# ENABLE command line arguments

rm(list=ls())

library(dplyr)
library(httr)		# used to download Teletext images
library(lubridate)	# deals with dates
library(twitteR)	# obvious
library(png)		# deals with PNG
library(tesseract)	# OCR
library(stringr)	# split expressions

## choose a working directory 
# setwd()

## preparing tesseract french engine
fra <- tesseract("fra")

## initialisation (uncomment/comment: only the first time!)
# a <- GET("http://api.teletext.ch/online/pics/medium/RTSUn_103-0.gif")
# crea <- dmy_hms(a$headers$'x-server-createdate')
# cat(as.character(crea), file="lastdate.txt")

## informations about the current page 103
url <- "http://api.teletext.ch/online/pics/medium/RTSUn_103-0.gif"
a <- GET(url)

## is it a new one or an old one?
crea.new <- dmy_hms(a$headers$'x-server-createdate')
crea.old <- ymd_hms(readLines("/app/persistent/lastdate.txt", warn=F))

## if a new one, then…
if (crea.new != crea.old) {
	
	## record your Twitter app
        api_key <- "XXX"
	api_secret <- "XXXX"
	access_token <- "XXXX"
	access_token_secret <- "XXX"

	## callback url http://127.0.0.1:1410

	## authentication
	options(httr_oauth_cache=TRUE) 
	setup_twitter_oauth(api_key, api_secret, access_token, access_token_secret)

	## we download the image
	download.file(url, "/app/persistent/hey.gif")

	## you need to have ImageMagick installed in order to use "convert"
	system("convert -verbose -coalesce /app/persistent/hey.gif /app/persistent/hey.png")
	system("convert -verbose /app/persistent/hey.png -fill black -fuzz 30% +opaque '#ffff00' /app/persistent/title.png")

	## we add columns to the left and the right in order to fit in Twitter format
	d <- readPNG("/app/persistent/hey.png")
        d <- d[,,1:3]

	## hey2.png must be manually created during the initialisation phase
	d2 <- readPNG("/app/persistent/hey2.png")
        d2 <- d2[,,1:3]

	title <-readPNG("/app/persistent/title.png")
	title <- title[,,1:3]

	## debug
	# test_value <- sum(d != d2) / length(d)
  	# cat("\nLe pourcentage de pixels différents est de ", test_value, "\n")
        
	## if the pages are different but that not that much,
	## it probably means that a misspell has been corrected
	## in that case we delete the last status before going on
	if (sum(d != d2) / length(d) > 0 && sum(d != d2) / length(d) < .03) {
		deleteStatus(userTimeline("teletext_ch_fr", 1)[[1]])
	}

	## if the current page is a new one or a corrected one, we post it
	if (sum(d != d2) != 0) {	
		
		## let's replace hey2.png for comparison next time
		writePNG(d,"/app/persistent/hey2.png")			
		
		## we remove the first two lines for the OCR
		# Previoulsy removing up to 42, now 36 for more space above text to improve OCR 
		writePNG(title[36:460,,],"/app/persistent/hey3.png")
		

		# Getting OCR data for FRA and ENG engines
		stat <- ocr_data("/app/persistent/hey3.png", engine=fra)
		stat2 <- ocr_data("/app/persistent/hey3.png")

		# Calculating mean of confidence for both engines
		mean = stat %>%
			summarise(mean = mean(confidence))
		mean2 = stat2 %>%
			summarise(mean = mean(confidence))

		# Selecting the best confidence
		if (mean > mean2) {
			txt <- ocr("/app/persistent/hey3.png", engine=fra)
		} else {
			txt <- ocr("/app/persistent/hey3.png")
		}
		
		## post tweet
		updateStatus(str_split(txt, "\n")[[1]][1], mediaPath="/app/persistent/hey2.png")
	}
	
	## update the date
	cat(as.character(crea.new), file="/app/persistent/lastdate.txt")	
}
