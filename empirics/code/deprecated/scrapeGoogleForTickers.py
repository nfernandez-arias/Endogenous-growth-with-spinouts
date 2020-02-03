from lib.google_search_results import GoogleSearchResults
import re
import csv

def extractPageFromGoogle(companyName):
    params = {
        "q" : f"{companyName} ticker symbol",
        "location" : "New York, New York, United States",
        "hl" : "en",
        "gl" : "us",
        "google_domain" : "google.com",
        "api_key" : "ea8844b4b82278532aaf2ef9d64d254cf0db59150b7e3b8e7d09752eccdfffcb",
        "output" : "html",
        "device" : "desktop",
    }

    client = GoogleSearchResults(params)
    #results = [client.get_html(), client.get_json()]
    results = client.get_html()

    return results

def extractTickerFromPage(html):

    try:
        found = re.search('<span class=\"HfMth\">(.+?)</span>', html).group(1)
    except AttributeError:
        # AAA, ZZZ not found in the original string
        found = ''

    return found

with open('company_list.csv', mode='r') as infile:
    reader = csv.reader(infile)
    firmsCounts = {rows[0]:rows[1] for rows in reader}

lb = 16500
ub = 17000

firmsPages = {firm:extractPageFromGoogle(firm) for firm in list(firmsCounts.keys())[lb:ub]}

# Extract ticker symbols from HTML
firmsTickers = {firm:extractTickerFromPage(page) for firm,page in list(firmsPages.items())}

#print(firmsHTML)
print(firmsTickers)
with open('firmsPages.csv', 'a') as csv_file:

    writer = csv.writer(csv_file)
    #writer.writerow(["Firm Name","HTML"])
    for key, value in firmsPages.items():
        writer.writerow([key,value])

#with open('firmsJSons.csv', 'a') as csv_file:

#    writer = csv.writer(csv_file)
    #writer.writerow(["Firm Name","JSon"])
#    for key, value in firmsJSons.items():
#        writer.writerow([key,value])

with open('firmsTickers.csv', 'a') as csv_file:
    writer = csv.writer(csv_file)
    #writer.writerow(["Firm Name","Ticker Symbol"])
    for key, value in firmsTickers.items():
       writer.writerow([key, value])
