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
        "api_key" : "9b66566f114d4a876cb052f3ff8d5ef682bf76424fdab1928f45433f1cf5f06d",
        "output" : "html",
        "device" : "desktop",
    }

    client = GoogleSearchResults(params)
    results = client.get_html()

    return results

def extractTickerFromPage(page):

    try:
        found = re.search('<span class=\"HfMth\">(.+?)</span>', page).group(1)
    except AttributeError:
        # AAA, ZZZ not found in the original string
        found = ''

    return found

with open('company_list.csv', mode='r') as infile:
    reader = csv.reader(infile)
    firmsCounts = {rows[0]:rows[1] for rows in reader}

firmsPages = {firm:extractPageFromGoogle(firm) for firm in list(firmsCounts.keys())[1:200]}
firmsTickers = {firm:extractTickerFromPage(page) for firm,page in list(firmsPages.items())[1:200]}

with open('firmsPages.csv', 'a') as csv_file:
    writer = csv.writer(csv_file)
    writer.writerow(["Firm Name","HTML"])
    for key, value in firmsPages.items():
        writer.writerow([key,value])

with open('firmsTickers.csv', 'a') as csv_file:
    writer = csv.writer(csv_file)
    writer.writerow(["Firm Name","Ticker Symbol"])
    for key, value in firmsTickers.items():
       writer.writerow([key, value])
