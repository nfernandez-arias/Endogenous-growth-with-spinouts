from lib.google_search_results import GoogleSearchResults
import re
import csv

def extractTickerFromGoogle(companyName):
    params = {
        "q" : f" \"{companyName}\" + \"ticker symbol\" ",
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

    try:
        found = re.search('<span class=\"HfMth\">(.+?)</span>', results).group(1)
    except AttributeError:
        # AAA, ZZZ not found in the original string
        found = ''

    return found


with open('company_list.csv', mode='r') as infile:
    reader = csv.reader(infile)
    firmsCounts = {rows[0]:rows[1] for rows in reader}

print(type(list(firmsCounts.keys())))

print(list(firmsCounts.keys())[3])

firmsTickers = {firm:extractTickerFromGoogle(firm) for firm in list(firmsCounts.keys())[1:15]}

with open('firmsTickers.csv', 'w') as csv_file:
    writer = csv.writer(csv_file)
    writer.writerow(["Firm Name","Ticker Symbol"])
    for key, value in firmsTickers.items():
       writer.writerow([key, value])
