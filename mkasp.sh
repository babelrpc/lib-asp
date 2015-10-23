#!/bin/bash

babel -lang asp -model -output . $GOPATH/etc/babeltemplates/error.babel
babel -lang asp -model -output . -options ext=vbs $GOPATH/etc/babeltemplates/error.babel

# build ASP versions of files
cat src/inc_babel_header.asp inc_babel.vbs src/inc_babel_footer.asp > inc_babel.asp
cat src/inc_json2_func_header.asp inc_json2_func.js src/inc_json2_func_footer.asp > inc_json2_func.asp
