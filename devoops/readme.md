Apache Reverse Proxy vuln to CVE-2021-41773

Behind the RP, there are three other services. 

1. Apache 2.4.49 
   - vuln to [CVE-2021-41773](https://www.randori.com/blog/cve-2021-41773/)
   - acts as RP for all other services - can hit it via the IP and get RCE
2. Gitlab
   - Vuln to [CVE-2022-1162](https://github.com/Greenwolf/CVE-2022-1162)
   - going to use keycloak
   1. Keycloak
      - used as SSO provider to setup Gitlab for exploitation
      - not likely to be vuln, but i'll plant a couple hidden flags just in case
      1. Mariadb
         - vuln to CVE-2021-27928
         - POCs require auth, they'd be stored in keycloak
   - [Setup Gitlab for KeyCloak](https://dheeruthedeployer.medium.com/gitlab-integration-with-keycloak-e1b2ff11a177)
     - TODO Once configured, create the users in keycloak, and assign passwords for their keycloak accounts
       - drahosj:SEyZwbk2ZASDdBwSZsen6wVUGU6SeXRy
       - papa:eRgZgHtJqWnDiPJTa7iAdcb9ZSP3vFNW
       - zoomequipd:JfcKdZyoSVxNcQbPd6FbZrzDu7wqqAgG
       - computer_freak_8:ejN2StaRikjn8GviLeLPS63TXzUL4ysN
       - rixon:CxDhYVed7vFwLFa9DZszK7j4Qt5pq2Ph
     - TODO Once accounts are created on keycloak, create the users on gitlab
       - populate repos
       - plant flags
4. Jira
   - vuln to CVE-2019-11581
   - no time to do. 
5. Jenkins
    - http://blog.orange.tw/2019/02/abusing-meta-programming-for-unauthenticated-rce.html
    - https://github.com/wetw0rk/Exploit-Development/blob/e40e3d995d89b0e293f4da6864156425ec1a00af/Ported-Exploits/CVE-2019-1003000_CVE-2018-1999002_exploit_chain.py
    - admin:Mr2TBkHokSiS94AyRe6duTTxXR4c97fi
6. Confluence
   - vuln to [CVE-2021-26084 (OGNL Template injection)](https://github.com/h3v0x/CVE-2021-26084_Confluence)
   - admin:tNL7bxC2JCRcpzAKB6pUj5vfwsT3eHK9
   1. postgres
    - no vulns here, at least that I know of
    - created a flag in a db
    