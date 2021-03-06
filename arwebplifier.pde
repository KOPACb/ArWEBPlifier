/* arwebplifier.pde - example sketch for Webduino library */


#include "SPI.h"
#include "Ethernet.h"
#include "WebServer.h"

template<class T>
inline Print &operator <<(Print &obj, T arg)
{ obj.print(arg); return obj; }


/*
Объявим переменные
*/
int vol1 = 0;
//web уровень звука
int dvol1 = 0;
int dvol1_t = 0;
// аналоговое чтение уровня 
int avol1 = 0;
int avol1_t = 0;
unsigned long time = -1;
// i-dle, a-nalog, d-igital
char spin = 'i';

// CHANGE THIS TO YOUR OWN UNIQUE VALUE
static uint8_t mac[6] = { 0x02, 0xAA, 0xBB, 0xCC, 0x00, 0x22 };

// CHANGE THIS TO MATCH YOUR HOST NETWORK
static uint8_t ip[4] = { 172, 16, 0, 210 }; // area 51!

/*Определим префикс и порт для Веб-сервера
*/
#define PREFIX "/vol"
WebServer webserver(PREFIX, 80);

/*
Инициализируем наши пины
*/
/* the piezo speaker on the Danger Shield is on PWM output pin #3 */
//шимим шим на 3й-пин ( крутим мотор там или любую другую логеку )
#define VPIN_1 3

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
       if (strcmp(name, "vol1") == 0)

      {
	/* Преобразуем значемне переменной из строки в числовой значение по основанию 10 
         * use the STRing TO Unsigned Long function to turn the string
	 * version of the delay number into our integer volDelay
	 * variable */
        dvol1 = strtoul(value, NULL, 10);
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
    P(top) = 
                 "<!DOCTYPE html><html><head>"
                 "<title>Webduino AJAX voler Example</title>"
                 "<link href='http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.16/themes/base/jquery-ui.css' rel=stylesheet />"
                 //"<meta http-equiv='Content-Script-Type' content='text/javascript'>"
                 "<script src='http://ajax.googleapis.com/ajax/libs/jquery/1.6.4/jquery.min.js'></script>"
                 "<script src='http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.16/jquery-ui.min.js'></script>"
                 "<style> #volume1 { margin: 10px; } </style>"
                 "<script>";
     server.printP(top);
     server <<   "var volum1 = " << vol1 << ";";                           
    P(bot) =     "function change1(event, ui) { jQuery.ajaxSetup({timeout: 110}); var id = $(this).attr('id'); if (id == 'volume1') $.post('/vol', { vol1: ui.value } );} "
                 "$(document).ready(function(){ $('#volume1').slider({min: 0, max:255, change:change1}); });"
                 
                 "</script>"
                 "</head>"
                 "<body style='font-size:62.5%;'>"
                 "<h1>Test the voler!</h1>"
                 "<div id=volume1></div>"
                 "<p id=indicator>0</p>"
                 "</body>"
                 "</html>";
    server.printP(bot);

  }
}

/*Изменяем громкость, в случае если крутилка была покручена
*/
void volume_change()
{
  if ( spin != 'i' )
  {
  Serial.println(spin);
  }
  if ( time != -1 )
   {
     if ( time <= millis() )
     {
     spin = 'i';
     Serial.println(spin);
     Serial.println(millis());

     time = -1;
     }
   }
   avol1_t = avol1;
   avol1 = map(analogRead(1), 0,1024,0,10);
   if ( avol1 != avol1_t)
   {
     if ( spin != 'd' )
     {
       vol1 = map(avol1, 0 , 10, 0, 255);
       spin = 'a';
     }
   }
   if ( avol1 == avol1_t) 
   {
     if  ( spin == 'a' )
      {
       analogWrite(3,map(avol1, 0 , 10, 0, 255));
       spin = 'i';
     }
   }
   if (dvol1 != dvol1_t) 
   {
     if ( spin != 'a' )
     {
       spin = 'd';
       analogWrite(3,dvol1);
       time = ( millis() + abs( dvol1 - vol1 ) * 1000);
       dvol1_t = dvol1;
       vol1 = dvol1;
       Serial.println(millis());
     }
   }
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
  // process incoming connections one at a time forever5
  webserver.processConnection();


   volume_change();
}
