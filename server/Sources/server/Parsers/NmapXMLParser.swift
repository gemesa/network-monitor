import Foundation

/*
 Example run:
 $ sudo nmap -sn 192.168.2.0/24 -oX - | xmllint --format -
 <?xml version="1.0" encoding="UTF-8"?>
 <!DOCTYPE nmaprun>
 <?xml-stylesheet href="file:///opt/homebrew/bin/../share/nmap/nmap.xsl" type="text/xsl"?>
 <!-- Nmap 7.98 scan initiated Tue Nov  4 18:54:40 2025 as: nmap -sn -oX - 192.168.2.0/24 -->
 <nmaprun scanner="nmap" args="nmap -sn -oX - 192.168.2.0/24" start="1762278880" startstr="Tue Nov  4 18:54:40 2025" version="7.98" xmloutputversion="1.05">
   <verbose level="0"/>
   <debugging level="0"/>
   ...
   <host>
     <status state="up" reason="arp-response" reason_ttl="0"/>
     <address addr="192.168.2.141" addrtype="ipv4"/>
     <address addr="XX:XX:XX:XX:XX:XX" addrtype="mac"/>
     <hostnames>
       <hostname name="Mac.lan" type="PTR"/>
     </hostnames>
     <times srtt="132132" rttvar="132132" to="660660"/>
   </host>
   ...
   <runstats>
     <finished time="1762278883" timestr="Tue Nov  4 18:54:43 2025" summary="Nmap done at Tue Nov  4 18:54:43 2025; 256 IP addresses (7 hosts up) scanned in 3.07 seconds" elapsed="3.07" exit="success"/>
     <hosts up="7" down="249" total="256"/>
   </runstats>
 </nmaprun>
 */

class NmapXMLParser: NSObject, XMLParserDelegate {
    private var hosts: [NmapHost] = []
    private var currentHost: NmapHost?

    func parse(data: Data) -> [NmapHost] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return hosts
    }

    func parser(
        _ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
        qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]
    ) {
        switch elementName {
        case "host":
            currentHost = NmapHost(ip: "", mac: nil, hostname: nil)
        case "address":
            if attributeDict["addrtype"] == "ipv4" {
                currentHost?.ip = attributeDict["addr"]!
            } else if attributeDict["addrtype"] == "mac" {
                currentHost?.mac = attributeDict["addr"]!
            }
        case "hostname":
            currentHost?.hostname = attributeDict["name"]
        default:
            break
        }
    }

    func parser(
        _ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        switch elementName {
        case "host":
            hosts.append(currentHost!)
        default:
            break
        }
    }
}
