import blepdroid.*;
import blepdroid.BlepdroidDevice;
import android.os.Bundle;
import android.content.Context;
import java.util.UUID;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;






BlepdroidDevice device1;
Blepdroid blepdroid;

boolean allSetUp = false;
boolean targetCharacteristicFound = false;
int whatPlot = 0;  //0: acc, 1:quat
public static String deviceName = "Tactg";
public static String TACTIGON_QUAT_CHAR_STRING = "7ac71000-503d-4920-b000-acc000000001";
public static UUID TACTIGON_QUAT_UUID = UUID.fromString(TACTIGON_QUAT_CHAR_STRING);


int[] xArray;
int[] yArray;
int[] zArray;
int[] wArray;

float xLast;
float yLast;
float zLast;
float wLast;


void setup() {
  //size(600, 800);
  fullScreen();
  smooth();
  println(" OK ");

  //create BLE class
  blepdroid = new Blepdroid(this);
  
  //init plotting arrays
  xArray = new int[width];  
  yArray = new int[width];
  zArray = new int[width];
  wArray = new int[width];
  for(int i=0; i<width; i++)
  {
    xArray[i] = (short)height/2;
    yArray[i] = (short)height/2;
    zArray[i] = (short)height/2;
    wArray[i] = (short)height/2;
  }
}

void draw() {

  
  if(allSetUp == false)
    background(100);
  else
  {
    background(10);    
    
    //plot
    for(int i=0; i<(width-1); i++)
    {
      stroke(255,0,0);
      strokeWeight(3);
      line(i, xArray[i], i+1, xArray[i+1]);
    }
    
    for(int i=0; i<(width-1); i++)
    {
      stroke(0,255,0);
      strokeWeight(3);
      line(i, yArray[i], i+1, yArray[i+1]);
    }
    
    for(int i=0; i<(width-1); i++)
    {
      stroke(255,0,255);
      strokeWeight(3);
      line(i, zArray[i], i+1, zArray[i+1]);
    }
    
    
    if(whatPlot == 0)
    {
      //plot accelerations
      
      textSize(32);
      textAlign(RIGHT);
      fill(255,0,0);
      text("X ACCEL", 130, 60);
      fill(0,255,0);
      text("Y ACCEL", 130, 100);
      fill(255,0,255);
      text("Z ACCEL", 130, 140);
    }
    else if(whatPlot == 1)
    {
      //plot quaternions
      
      textSize(32);
      textAlign(LEFT);
      
      fill(255,255,255);
      text("q0 ", 130, 60);     text(wLast, 200, 60);        
      fill(255,0,0);
      text("q1 ", 130, 100);    text(xLast, 200, 100);
      fill(0,255,0);
      text("q2 ", 130, 140);    text(yLast, 200, 140);
      fill(255,0,255);
      text("q3 ", 130, 180);    text(zLast, 200, 180);
      
      
      for(int i=0; i<(width-1); i++)
      {
        stroke(255,255,255);
        strokeWeight(3);
        line(i, wArray[i], i+1, wArray[i+1]);
      }
    }
    
  }
  fill(10);
}




//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void mousePressed()
{ 

  if(targetCharacteristicFound == false)
  {
    println(" scan !");
    blepdroid.scanDevices();
  }
  else
  {
    //toggle acc/quat plotting
    whatPlot = (whatPlot + 1) % 2;
    println("plot changed" + whatPlot);
    
    for(int i=0; i<width; i++)
    {
      xArray[i] = (int)height/2;
      yArray[i] = (int)height/2;
      zArray[i] = (int)height/2;
      wArray[i] = (int)height/2;
    }
  }

}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void onDeviceDiscovered(BlepdroidDevice device)
{
  println("discovered device " + device.name + " address: " + device.address + " rssi: " + device.rssi );

  if (device.name != null && device.name.equals(deviceName))
  {
    println("Device Found");
    
    if (blepdroid.connectDevice(device))
    {
      println(" connected!");
      
      device1 = device;
      
    } else
    {
      println(" couldn't connect target device ");
    }
  } 
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void onServicesDiscovered(BlepdroidDevice device, int status)
{
  
  HashMap<String, ArrayList<String>> servicesAndCharas = blepdroid.findAllServicesCharacteristics(device);
  
  for( String service : servicesAndCharas.keySet())
  {
    print( service + " has " );
    
    // this will list the UUIDs of each service, in the future we're going to make
    // this tell you more about each characteristic, e.g. whether it's readable or writable
    //println( servicesAndCharas.get(service));
    
    for(String charact: servicesAndCharas.get(service))
    {
      print( " charact: " + charact);
      if(charact.equals(TACTIGON_QUAT_CHAR_STRING))
      {
        targetCharacteristicFound = true;
        print( " target characteristic found! ");
        blepdroid.setCharacteristicToListen(device, TACTIGON_QUAT_UUID);
      }
    }
    
  }
  
  // we want to set this for whatever device we just connected to
  //blepdroid.setCharacteristicToListen(device, RFDUINO_UUID_RECEIVE);

  allSetUp = true;
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// these are all the BLE callbacks
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void onBluetoothRSSI(BlepdroidDevice device, int rssi)
{
  println(" onBluetoothRSSI " + device.address + " " + Integer.toString(rssi));
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void onBluetoothConnection( BlepdroidDevice device, int state)
{
  blepdroid.discoverServices(device);
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void onCharacteristicChanged(BlepdroidDevice device, String characteristic, byte[] data)
{
  //   q0(2) | q1(2) | q2(2) | q3(2) | acc1(2) | acc2(2) | acc3(2) |
  
  if(whatPlot == 0)
  {  
    //get accelerations from BLE characteristic    
    byte[] xb = new byte[2];
    byte[] yb = new byte[2];
    byte[] zb = new byte[2];
  
    System.arraycopy( data, 8, xb, 0, 2 );
    System.arraycopy( data, 10, yb, 0, 2 );
    System.arraycopy( data, 12, zb, 0, 2 );
  
    short x = ByteBuffer.wrap(xb).order(ByteOrder.LITTLE_ENDIAN).getShort();
    short y = ByteBuffer.wrap(yb).order(ByteOrder.LITTLE_ENDIAN).getShort();
    short z = ByteBuffer.wrap(zb).order(ByteOrder.LITTLE_ENDIAN).getShort();
  
    //scale last values on display size
    //
    // 0 on display center, assume a FullScale of 8000 millig
    //
    float x_scaled = ((float)x)/8000*(height/2) + height/2;
    float y_scaled = ((float)y)/8000*(height/2) + height/2;
    float z_scaled = ((float)z)/8000*(height/2) + height/2;
  
    //left shift plotting arrays
    for(int i=0; i<(width-1); i++)
    {
      xArray[i] = xArray[i+1];
      yArray[i] = yArray[i+1];
      zArray[i] = zArray[i+1];
    }
  
    //add last value in plotting arrays
    xArray[width - 1] = (int)x_scaled;        
    yArray[width - 1] = (int)y_scaled;        
    zArray[width - 1] = (int)z_scaled;        
  }
  else if(whatPlot == 1)
  {
    //get quaternions from BLE characteristic
    byte[] wb = new byte[2];
    byte[] xb = new byte[2];
    byte[] yb = new byte[2];
    byte[] zb = new byte[2];
      
    System.arraycopy( data, 0, wb, 0, 2 );
    System.arraycopy( data, 2, xb, 0, 2 );
    System.arraycopy( data, 4, yb, 0, 2 );
    System.arraycopy( data, 6, zb, 0, 2 );
  
    short w = ByteBuffer.wrap(wb).order(ByteOrder.LITTLE_ENDIAN).getShort();
    short x = ByteBuffer.wrap(xb).order(ByteOrder.LITTLE_ENDIAN).getShort();
    short y = ByteBuffer.wrap(yb).order(ByteOrder.LITTLE_ENDIAN).getShort();
    short z = ByteBuffer.wrap(zb).order(ByteOrder.LITTLE_ENDIAN).getShort();
    
  
    //scale last values on display size
    //
    // quaternons values are provided as short integer with range [-32767,+32767] corresponding to quaternions standard range [-1,1]
    //
    xLast = ((float)x)/32767;
    float x_scaled = xLast*(height/2-10) + height/2;
    
    yLast = ((float)y)/32767;
    float y_scaled = yLast*(height/2-10) + height/2;
    
    zLast = ((float)z)/32767;
    float z_scaled = zLast*(height/2-10) + height/2;
    
    wLast = ((float)w)/32767;
    float w_scaled = wLast*(height/2-10) + height/2;
    
  
    //left shift plotting arrays
    for(int i=0; i<(width-1); i++)
    {
      xArray[i] = xArray[i+1];
      yArray[i] = yArray[i+1];
      zArray[i] = zArray[i+1];
      wArray[i] = wArray[i+1];
    }
    
    //add last value in plotting arrays
    xArray[width - 1] = (int)x_scaled;        
    yArray[width - 1] = (int)y_scaled;        
    zArray[width - 1] = (int)z_scaled;        
    wArray[width - 1] = (int)w_scaled;    
  }
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void onDescriptorWrite(BlepdroidDevice device, String characteristic, String data)
{
  println(" onDescriptorWrite " + characteristic + " " + data);
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void onDescriptorRead(BlepdroidDevice device, String characteristic, String data)
{
  println(" onDescriptorRead " + characteristic + " " + data);
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void onCharacteristicRead(BlepdroidDevice device, String characteristic, byte[] data)
{
  println(" onCharacteristicRead " + characteristic + " " + data);
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void onCharacteristicWrite(BlepdroidDevice device, String characteristic, byte[] data)
{
  println(" onCharacteristicWrite " + characteristic + " " + data);
}