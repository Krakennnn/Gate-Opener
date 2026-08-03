#include <Arduino.h>
#line 1 "C:\\Users\\wjas0\\Documents\\GitHub\\Gate-Opener\\GateOpenerProgram\\Rev3\\LLSketch\\LLSketch.ino"
#include <AlPlc_Opta.h>

/* opta_1.3.0
*/

struct PLCSharedVarsInput_t
{
};
PLCSharedVarsInput_t& PLCIn = (PLCSharedVarsInput_t&)m_PLCSharedVarsInputBuf;

struct PLCSharedVarsOutput_t
{
};
PLCSharedVarsOutput_t& PLCOut = (PLCSharedVarsOutput_t&)m_PLCSharedVarsOutputBuf;


AlPlc AxelPLC(766738579, false);

#include <Ethernet.h>
#include <NTPClient.h>
EthernetUDP NTPUdp;
NTPClient timeClient(NTPUdp);

#line 24 "C:\\Users\\wjas0\\Documents\\GitHub\\Gate-Opener\\GateOpenerProgram\\Rev3\\LLSketch\\LLSketch.ino"
void setup();
#line 36 "C:\\Users\\wjas0\\Documents\\GitHub\\Gate-Opener\\GateOpenerProgram\\Rev3\\LLSketch\\LLSketch.ino"
void loop();
#line 24 "C:\\Users\\wjas0\\Documents\\GitHub\\Gate-Opener\\GateOpenerProgram\\Rev3\\LLSketch\\LLSketch.ino"
void setup() {
    // Start Ethernet over physical RJ-45 cable
   
	IPAddress eth_ip(192,168,0,100);
	IPAddress eth_subnet(255,255,255,0);
	IPAddress eth_gateway(196,168,0,1);
	IPAddress eth_dns(196,168,0,1);
	Ethernet.begin(nullptr, eth_ip, eth_dns, eth_gateway, eth_subnet, 5000);
	
	AxelPLC.Run();
}

void loop() {
	delay(1);
	
	if (Ethernet.linkStatus() == LinkON) {
		if (timeClient.update())
			set_time(timeClient.getEpochTime());
	}
	
    // Leave loop running smoothly so USB CDC thread doesn't freeze
}

