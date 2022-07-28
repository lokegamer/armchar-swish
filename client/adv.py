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

output = [ "\\documentclass{scrartcl}",
           "\\title{Advancement Log}",
           "\\author{armchar example}",
           "\\begin{document}",
           "\\titlepage" ]

y = get(conn,"/adv/cieran" )

output.append( "\\begin{description}" )

for i in y:
    c = i["advancementcontents"] 
    print (c)
    output.append( f'  \\item[{c.get( "arm:atSeason", "")} {c.get("arm:inYear","-")}]' )
    output.append( f'    {c.get( "arm:hasAdvancementDescription", "")}' )
    output.append( '' )
    output.append( f'    {c.get( "arm:hasAdvancementTypeString", "")} awards {c.get( "arm:awardsXP", "?")}xp' )

    ts = i.get("advancementtraits",{})
    output.append( "    \\begin{itemize}" )
    for t in ts:
        output.append( f'      \\item {t.get("arm:hasLabel","???")}: {t.get("arm:addedXP","?")}xp' )
    output.append( "    \\end{itemize}" )

output.append( "\\end{description}" )

output.append(  "\\end{document}" )
f = open("adv.tex", "w")
for line in output:
    f.write(line+"\n")
f.close()
