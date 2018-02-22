# -*- coding: utf-8 -*-
"""
Created on Wed Sep 20 21:38:08 2017

@author: Nico
"""

from bs4 import BeautifulSoup as bs
import urllib3

def scrape_industries(site = 'https://angel.co/markets'):
    http = urllib3.PoolManager()
    
    r = http.request('GET', site)
    if r.status != 200:
        return False
    
    soup = bs(r.data)
    
    return [link.get_text().encode('utf-8') for link in [line.find('a') for line in soup.find_all('div', {'class' :'item-tag'})]]

if __name__ == '__main__':
    print(sorted(scrape_industries()))