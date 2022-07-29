#! /usr/bin/env python3

import http.client, urllib.parse
import json

def get(conn,path):
   conn.request("GET", path)
   response = conn.getresponse()
   print(path,response.status, response.reason)
   data = response.read()
   return json.loads(data)

conn = http.client.HTTPConnection("localhost:3000")

output = [ "\\documentclass{armsheet}", "\\begin{magus}" ]

y = get(conn,"/char/cieran" )

if y.__contains__( "arm:hasPlayer" ): 
       output.append( f"\\player{{{y['arm:hasPlayer']}}}" )
if y.__contains__( "arm:hasSaga" ): 
       output.append( f"\\saga{{{y['arm:hasSaga']}}}" )
if y.__contains__( "arm:hasBirthYear" ): 
       output.append( f"\\born{{{y['arm:hasBirthYear']}}}" )
if y.__contains__( "arm:hasGender" ): 
       output.append( f"\\gender{{{y['arm:hasGender']}}}" )
if y.__contains__( "arm:hasName" ): 
       output.append( f"\\name{{{y['arm:hasName']}}}" )
if y.__contains__( "arm:hasNationality" ): 
       output.append( f"\\nationality{{{y['arm:hasNationality']}}}" )
if y.__contains__( "arm:hasProfession" ): 
       output.append( f"\\concept{{{y['arm:hasProfession']}}}" )

#   "arm:hasAlmaMater": "Stonehenge",


y = get(conn,"/ability/cieran/1217/Autumn" )

ab = [ (i.get("arm:hasLabel","???"),i.get("arm:hasSpeciality","-"),i.get("arm:hasScore","-"),i.get("arm:hasXP","-")) for i in y ]
ab.sort()


output.append( "\\begin{abilities}" )
for i in ab:
    output.append( f"  \\Anability[{i[1]}]{{{i[0]}}}{{{i[2]}}}{{{i[3]}}}" )
output.append( "\\end{abilities}" )


y = get(conn,"/virtue/cieran/1217/Autumn" )
y += get(conn,"/flaw/cieran/1217/Autumn" )

output.append( "\\begin{vf}" )
for i in y:
    output.append( f"  \\vfLine{{{i.get('arm:hasLabel','???')}}}{{{i.get('arm:hasScore','?')}}}" )
output.append( "\\end{vf}" )

y = get(conn,"/pt/cieran/1217/Autumn" )
output.append( "\\begin{personality}" )
for i in y:
    output.append( f"  \\aPtrait{{{i.get('arm:hasLabel','???')}}}{{{i.get('arm:hasScore','?')}}}" )
output.append( "\\end{personality}" )

y = get(conn,"/characteristic/cieran/1217/Autumn" )
for i in y:
    output.append( f'\Characteristic{{{i.get("arm:hasScore","?")}}}{{{i.get("arm:hasAbbreviation","?").lower()}}}' )

y = get(conn,"/art/cieran/1217/Autumn" )

for i in y:
    output.append( f'\AnArt{{{i.get("arm:hasLabel","?").lower()}}}{{{i.get("arm:hasScore","?")}}}{{{i.get("arm:hasXP","?")}}}{{{i.get("arm:hasVis","-")}}}' )


output.append(  "\\end{magus}" )
f = open("magus.tex", "w")
for line in output:
    f.write(line+"\n")
f.close()