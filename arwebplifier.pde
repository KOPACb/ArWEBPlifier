/* arwebplifier.pde - */


#include "SPI.h"
#include "Ethernet.h"
#include "WebServer.h"


/*
Объявим переменные
*/
int vol1 = 0;
int vol1_t = 0;
int avol1 = 0;
int avol1_t = 0;

//mac address
static uint8_t mac[6] = { 0x02, 0xAA, 0xBB, 0xCC, 0x00, 0x22 };

// CHANGE THIS TO MATCH YOUR HOST NETWORK
// static uint8_t ip[4] = { 172, 16, 0, 210 }; // area 51!

/*Определим префикс и порт для Веб-сервера
*/
#define PREFIX "/vol"
WebServer webserver(PREFIX, 80);

/*
Инициализируем наши пины
*/
/* the piezo speaker on the Danger Shield is on PWM output pin #3 */
#define VPIN_1 3



/* toggle is used to only turn on the speaker every other loop
iteration. */
char toggle = 0;


/* This command is set as the default command for the server.  It
 * handles both GET and POST requests.  For a GET, it returns a simple
 * page with some buttons.  For a POST, it saves the value posted to
 * the volDelay variable, affecting the output of the speaker */
void volCmd(WebServer &server, WebServer::ConnectionType type, char *, bool)
{
  if (type == WebServer::POST)
  {
    bool repeat;
    char name[16], value[16];
    do
    {
      /* readPOSTparam returns false when there are no more parameters
       * to read from the input.  We pass in buffers for it to store
       * the name and value strings along with the length of those
       * buffers. */
      repeat = server.readPOSTparam(name, 16, value, 16);

      /* this is a standard string comparison function.  It returns 0
       * when there's an exact match.  We're looking for a parameter
       * named "vol" here. */
       if (strcmp(name, "/vol") == 0)

      {
	/* Преобразуем значемне переменной из строки в числовой значение по основанию 10 
         * use the STRing TO Unsigned Long function to turn the string
	 * version of the delay number into our integer volDelay
	 * variable */
        vol1 = strtoul(value, NULL, 10);
      }
    } while (repeat);
    
    // after procesing the POST data, tell the web browser to reload
    // the page using a GET method. 
    server.httpSeeOther(PREFIX);
    return;
  }
  /* for a GET or HEAD, send the standard "it's all OK headers" */
  server.httpSuccess();

  /* we don't output the body for a HEAD request */
  if (type == WebServer::GET)
  {
   /* store the HTML in program memory using the P macro */
    P(message) = 
                 "<!DOCTYPE html><html><head>"
                 "<title>Webduino AJAX voler Example</title>"
                 "<link href='http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.16/themes/base/jquery-ui.css' rel=stylesheet />"
                 //"<meta http-equiv='Content-Script-Type' content='text/javascript'>"
                 "<script src='http://ajax.googleapis.com/ajax/libs/jquery/1.6.4/jquery.min.js'></script>"
                 "<script src='http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.16/jquery-ui.min.js'></script>"
                 "<style> #slider { margin: 10px; } </style>"
                 "<script>"
                           "function changevol(event, ui) { $('#indicator').text(ui.value); $.post('/vol', { vol: ui.value } ); }"
                           "$(document).ready(function(){ $('#slider').slider({min: 0, max:8000, change:changevol}); });"
                 "</script>"
                 "</head>"
                 "<body style='font-size:62.5%;'>"
                 "<h1>Test the voler!</h1>"
                 "<div id=slider></div>"
                 "<p id=indicator>0</p>"
                 "</body>"
                 "</html>";

    server.printP(message);

  }
}




/*Изменяем громкость, в случае если крутилка была покручена
*/
void volume_change()
{
   avol1_t = avol1;
   avol1 = analogRead(1);
   if ( avol1 != avol1_t)
   {
       analogWrite(3,map(avol1, 0 , 1024, 0, 255));
       vol1 = map(avol1, 0 , 1024, 0, 8000);
   }

   if (vol1 != vol1_t) 
   {

       analogWrite(3,map(vol1, 0 , 8000, 0, 255));
   }

   vol1_t = vol1;
   Serial.println(21);
   Serial.println(avol1); 
   Serial.println(avol1_t);
   Serial.println(vol1); 
   Serial.println(vol1_t); 
   Serial.flush();
}



/*Настраиваем настройки для инициализации контроллера
*/
void setup()
{
  /*Для отладки
  */
   Serial.begin(9600);

  // set the PWM output for the voler to out
  pinMode(VPIN_1, OUTPUT);

  // Настраиваем Ethernet-порт на DHCP, mac -  02::AA:BB:CC:00:22 
  Ethernet.begin(mac);

  /* register our default command (activated with the request of
   * http://x.x.x.x/vol */
  webserver.setDefaultCommand(&volCmd);

  /* start the server to wait for connections */
  webserver.begin();
}


void loop()
{
  // process incoming connections one at a time forever
  webserver.processConnection();

  /* every other time through the loop, turn on and off the speaker if
   * our delay isn't set to 0. */
//  if ((++toggle & 1))
//  {
   volume_change();
//  }
}
