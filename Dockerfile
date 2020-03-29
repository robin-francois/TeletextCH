FROM alpine:latest

RUN apk add --no-cache bash bash-doc bash-completion R R-dev build-base
RUN apk add --no-cache libcurl tesseract-ocr-dev leptonica-dev curl-dev libjpeg jpeg-dev poppler-dev imagemagick

WORKDIR /app

ADD *.R ./
ADD lastdate.txt ./
ADD *.png ./ 

RUN /usr/bin/Rscript /app/install_packages.R

RUN /usr/bin/Rscript /app/install_lang.R

CMD /usr/bin/Rscript /app/teletextch.R

