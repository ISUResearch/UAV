import processing.serial.*;

Serial port;

int state;
int len;
int compID;
int msgID;
byte payload[];
int ptr;

int count;

float pitch, yaw, roll, press, offset;
float px, py, pz, vx, vy, vz, ax, ay, az;

long timeAtt, timePres;

void setup() {
  size(1200, 800, P3D);
  
  state = 0;
  
  px = py = pz = vx = vy = vz = press = 0;
  timeAtt = timePres = 0;
  count = 0;
  
  port = new Serial(this, Serial.list()[0], 57600);
}

void draw() {
  clear();
  background(96, 112, 192);
  spotLight(255, 255, 255, 600, 0, 0, 0, 1, 0, PI/3, 1);
  ambientLight(128, 128, 128);
  camera(width*1.5, height/2, -width, width/2, height/2, 0, 0, 1, 0);
  
  translate(600, 800, 0);
  fill(96, 255, 96);
  box(1.5*width, 1, 1.5*width);
  
  translate(-600, -800, 0);
  
  stroke(255, 255, 255);
  line(width/2, height, 0, width/2 - 10000, height, 0);
  line(width/2, height, 0, width/2, height - 10000, 0);
  line(width/2, height, 0, width/2, height, 10000);
  
  translate(600 + py*100, 750 + pz*100, -px*100);
  rotateY(-yaw);
  rotateZ(-roll);
  rotateX(pitch);
  fill(96, 96, 96);
  stroke(64, 64, 64);
  box(200, 50, 200);
  line(py, pz, -px, py + ay * 200, pz - az*200, ax*200 - px);
}


void serialEvent(Serial port) {
  int data = port.read();
  
  ReadByte(data);
}

void ReadByte(int data) {
  switch(state) {
    case 0:
      if(data == 0xFE) {
        state = 1;
        ptr = 0;
      }
    break;
    
    case 1:
      len = data;
      payload = new byte[len];
      state = 2;
    break;
    
    case 2:
      state = 3;
    break;
    
    case 3:
      state = 4;
    break;
    
    case 4:
      compID = data;
      state = 5;
    break;
    
    case 5:
      msgID = data;
      state = 6;
    break;
    
    case 6:
      payload[ptr++] = (byte)data;
      if(ptr == len)
        state = 7;
    break;
    
    case 7:
      state = 8;
    break;
    
    case 8:
      state = 0;
      
      Packet();
    break;
  }
    
}

void Packet() {
  if(msgID == 30) {
    float dt = 0;
    
    if(timeAtt != 0)
      dt = (millis() - timeAtt)*0.001f;
    
    timeAtt = millis();
    
    roll = Float.intBitsToFloat((payload[4] & 0xFF) | ((payload[5] & 0xFF) << 8) | ((payload[6] & 0xFF) << 16) | ((payload[7] & 0xFF) << 24));
    pitch = Float.intBitsToFloat((payload[8] & 0xFF) | ((payload[9] & 0xFF) << 8) | ((payload[10] & 0xFF) << 16) | ((payload[11] & 0xFF) << 24));
    yaw = Float.intBitsToFloat((payload[12] & 0xFF) | ((payload[13] & 0xFF) << 8) | ((payload[14] & 0xFF) << 16) | ((payload[15] & 0xFF) << 24));
    
    if(dt == 0) {
      offset = yaw;
      yaw = 0;
    }
    else {
      yaw -= offset;
      if (yaw > PI)
        yaw -= 2*PI;
      else if(yaw < -PI)
        yaw += 2*PI;
    }
    
    ax = cos(yaw)*sin(pitch)*cos(roll) + sin(yaw)*sin(roll);
    ay = sin(yaw)*sin(pitch)*cos(roll) - cos(yaw)*sin(roll);
    az = cos(pitch)*cos(roll);
    
    println(pitch*180/PI + "   " + yaw*180/PI + "    " + roll*180/PI + "    " + ax + "    " + ay + "    " + az);
    
    px += vx*dt + 0.5f*ax*dt*dt;
    py += vy*dt + 0.5f*ay*dt*dt;
    pz += 0;//vz*dt + 0.5f*az*dt*dt;
    
    vx += ax*dt;
    vy += ay*dt;
    vz += az*dt;
  }
  else if(msgID == 29) {
    	press = Float.intBitsToFloat((payload[4] & 0xFF) | ((payload[5] & 0xFF) << 8) | ((payload[6] & 0xFF) << 16) | ((payload[7] & 0xFF) << 24));
  	}
}
