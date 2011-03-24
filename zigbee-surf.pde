/* Zigbee Channel Surfing

This is small adaptation to the Freakduino example 9 code. It enables
scanning through each zigbee channel to find active communications
for analysis.

Original notes:
chibiArduino Wireshark Bridge, Example 9
This sketch enables promiscuous mode on the Freakduino boards and dumps
the raw 802.15.4 frames out to the serial port. It should be used in 
conjunction with the FreakLabs "wsbridge" application to feed the raw
frames into Wireshark.

Before using this sketch, please go into the chibiUsrCfg.h file and 
enable promiscuous mode. To do this, change the definition:

#define CHIBI_PROMISCUOUS 0
to 
#define CHIBI_PROMISCUOUS 1

When not using promiscuous mode, please disable this setting by changing
it back to 0.
*/

#include <chibi.h>
#include <TimedAction.h>

int ledPin = 13;
int chan = 0x0b;
int report = 1;
TimedAction rotate_chan = TimedAction(1000,next_chan);
TimedAction rotate_en_check = TimedAction(30000,en_rotate_check);

/**************************************************************************/
// Initialize
/**************************************************************************/
void setup()
{  
  // Init the chibi stack
  chibiInit();              
  
  Serial.begin(115200);

  chibiSetChannel(0x0b);
  
  // TODO: add support for non-zigbee output, this will cause alignment problems with wsbridge 
  //Serial.println("Initialized."); 
  
  pinMode(ledPin, OUTPUT);
}

/**************************************************************************/
// Loop
/**************************************************************************/
void loop()
{
  rotate_chan.check();
  rotate_en_check.check();
  
  // Check if any data was received from the radio. If so, then handle it.
  if (chibiDataRcvd() == true)
  {
    // If we find data on this channel, stop channel surfing for a bit
    rotate_chan.disable();
    // Reset time_left until channel rotation is re-enabled while we are
    // still getting data on the current channel
    rotate_en_check.reset(); 
    if( report ){
      // Uncomment to enable channel reporting.
      //Serial.print("Channel:");
      //Serial.println(chan,HEX);
      report = 0;
    } 
     
    int len;
    byte buf[CHB_MAX_PAYLOAD]; 
    
    // send the raw data out the serial port in binary format
    len = chibiGetData(buf);

    Serial.write(buf, len);
  }
}

/*********************************************************
 * Handle rotating through the supported zigbee channels *
 *********************************************************/
void next_chan() {
  if( chan >= 0x1a ){
    chan = 0x0b;
  } else {
    chan++;
    // More data we can't send to wsbridge
    // You can enable this, but you won't get valid reporting in Wireshark
    //Serial.print("Channel: ");
    //Serial.println(chan, HEX);
  }
  chibiSetChannel(chan);
}

/************************************************************
 * Resumes channel surfing                                  *
 * After set period of no data turn channel surfing back on *
 ************************************************************/
void en_rotate_check() {
  rotate_chan.enable();
  report = 1;
  //Serial.println("En-rotate");
}

