6 => int numLoops;

//setup
SndBuf files[numLoops];
Envelope env[numLoops][8];
string filename[numLoops];
int pan[numLoops];
int pan_history[numLoops];
int dw[numLoops];
int dw_history[numLoops];
Envelope gainEnv[numLoops];
float rpm[numLoops];

//load files
"/Volumes/Data/Desktop/tikiTaka/pads.aif" => files[0].read;
"/Volumes/Data/Desktop/tikiTaka/drums.aif" => files[1].read;
"/Volumes/Data/Desktop/tikiTaka/bass.aif" => files[2].read;
"/Volumes/Data/Desktop/tikiTaka/lead.aif" => files[3].read;
"/Volumes/Data/Desktop/tikiTaka/lead2.aif" => files[4].read;
//"/Volumes/Data/Desktop/tiki taka FULL TOP.aif" => files[5].read;

//init
for (0 => int i;i<numLoops;i++)
{
    0 => pan[i];
    0 => pan_history[i];
    0 => dw[i];
    0 => dw_history[i];
    0 => rpm[i];
    //SET LOOPS IF NEEDED
    files[i].loop(0);
    files[i] => gainEnv[i];
    if (i!=5)
    {   
        for (0 => int j;j<8;j++)
        {
            gainEnv[i] => env[i][j] => dac.chan(j);            
            gainEnv[i].value(1);
            env[i][j].value(0.35);
        }   
    }
    else 
    {
        for (0 => int j;j<8;j++)
        {
            //gainEnv[i] => env[i][j] => dac.chan(0); // TOP CHANNEL - put top channel here
            gainEnv[i].value(1);
            env[i][j].value(1);
        }   
    }
}


// create our OSC receiver
OscRecv recv;
// use port
8888 => recv.port;
// start listening (launch thread)
recv.listen();

// create an address in the receiver, store in new variable
recv.event( "/pan, ii" ) @=> OscEvent oe1;
recv.event( "/dw, ii" ) @=> OscEvent oe2;
recv.event( "/levels, fi" ) @=> OscEvent oe4;
recv.event( "/position, ffi" ) @=> OscEvent oe5;
recv.event( "/frequency, fi" ) @=> OscEvent oe6;

fun void getLevel()
{
    while ( true )
    {
        // wait for event to arrive
        oe4 => now;
        
        // grab the next message from the queue. 
        while ( oe4.nextMsg() != 0 )
        { 
            // getFloat fetches the expected float (as indicated by "f")
            oe4.getFloat() => float f;
            oe4.getInt() => int i;
            // print
            //<<< i >>>;
            //<<< s >>>;
            
            gainEnv[i].target(f);
            gainEnv[i].time(0.05);
        }
        
    }
    
}


fun void getPosition()
{
    while ( true )
    {
        // wait for event to arrive
        oe5 => now;
        
        // grab the next message from the queue. 
        while ( oe5.nextMsg() != 0 )
        { 
            <<<"got pos">>>;
            // getFloat fetches the expected float (as indicated by "f")
            oe5.getFloat() => float x;
            oe5.getFloat() => float y;
            oe5.getInt() => int i;
            //set pan level
            panForPosition(x,y,i);
        }   
    }
    
}


fun void panForPosition(float x,float y, int i)
{
    0.785398 => float theta; // 2pi/8
    float gain_buff[8];            
    float proportion[8];
    0 => float proportion_sum;
    [0,1,3,5,7,6,4,2] @=> int speaker_order[];
    for (0 => int k;k<8;k++)
    {
        Math.cos(k*theta+Math.PI+3*theta/2) => float vertexX;
        Math.sin(k*theta+Math.PI+3*theta/2) => float vertexY;  
        (vertexX-x)*(vertexX-x)+(vertexY-y)*(vertexY-y) => float dist_sq;
        (1/dist_sq) => proportion[speaker_order[k]];
        
    }
    for (0 => int k;k<8;k++)
    {
        proportion_sum + proportion[speaker_order[k]] => proportion_sum;
    }
    0 => float gain_sum;
    for (0 => int k;k<8;k++)
    {
        Math.pow(proportion[speaker_order[k]] / proportion_sum,0.5) => gain_buff[speaker_order[k]];
        <<<[speaker_order[k]] + " - " + gain_buff[speaker_order[k]]>>>;                
        gain_sum+gain_buff[speaker_order[k]]*gain_buff[speaker_order[k]]=>gain_sum;
    }
    <<<gain_sum>>>;
    setGain(i,gain_buff);   
}


fun void getPan()
{
    while ( true )
    {
        <<< "got pan" >>>;
        // wait for event to arrive
        oe1 => now;
        
        // grab the next message from the queue. 
        while ( oe1.nextMsg() != 0 )
        { 
            // getFloat fetches the expected float (as indicated by "f")
            oe1.getInt() => int panBool;
            oe1.getInt() => int i;
            panBool => pan[i];
            spork ~pan8(i);
        }
    }
    
}

fun void getDw()
{
    while ( true )
    {
        // wait for event to arrive
        oe2 => now;
        
        // grab the next message from the queue. 
        while ( oe2.nextMsg() != 0 )
        { 
            // getFloat fetches the expected float (as indicated by "f")
            oe2.getInt() => int dwBool;
            oe2.getInt() => int i;
            // print

           dwBool => dw[i];
           spork ~drunkenWalk(i);
        }
    }
    
}

fun void getFrequency()
{
    while ( true )
    {
        // wait for event to arrive
        oe6 => now;
        
        // grab the next message from the queue. 
        while ( oe6.nextMsg() != 0 )
        { 
            // getFloat fetches the expected float (as indicated by "f")
            oe6.getFloat() => float freq;
            oe6.getInt() => int i;
            // print
            (freq-0.5)*400 => rpm[i];
        }
    }
    
}



fun void setGain(int channel,float gain_buff[])
{
    for (0 => int i;i<8;i++)
    {
        env[channel][i].target(gain_buff[i]);
        env[channel][i].time(0.05);
    }
}


fun void pan8(int channel)
{
    float rpmvalue;
    float gain_buff[8];
    [1,3,5,7,6,4,2,0] @=> int speaker_order[];
    while(pan[channel] == 1)
    {
        <<<rpm[channel]>>>;
        for (0 => int j;j<8;j++)
        {
            if (rpm[channel] >= 0)
            {
                0.9791 => gain_buff[speaker_order[(j+1)%8]];
                0.1034 => gain_buff[speaker_order[(j+2)%8]];
                0.0593 => gain_buff[speaker_order[(j+3)%8]];
                0.0466 => gain_buff[speaker_order[(j+4)%8]];
                0.0438 => gain_buff[speaker_order[(j+5)%8]];
                0.0484 => gain_buff[speaker_order[(j+6)%8]];
                0.0649 => gain_buff[speaker_order[(j+7)%8]];
                0.1285 => gain_buff[speaker_order[(j+8)%8]];
                rpm[channel] => rpmvalue;
            }
            if (rpm[channel] < 0)
            {
                0.9791 => gain_buff[speaker_order[(7-j+1)%8]];
                0.1034 => gain_buff[speaker_order[(7-j+2)%8]];
                0.0593 => gain_buff[speaker_order[(7-j+3)%8]];
                0.0466 => gain_buff[speaker_order[(7-j+4)%8]];
                0.0438 => gain_buff[speaker_order[(7-j+5)%8]];
                0.0484 => gain_buff[speaker_order[(7-j+6)%8]];
                0.0649 => gain_buff[speaker_order[(7-j+7)%8]];
                0.1285 => gain_buff[speaker_order[(7-j+8)%8]];
                -1*rpm[channel] => rpmvalue;
            }
            setGain(channel,gain_buff);
            60/(rpmvalue*8)=>float val;
            val::second=>now;
        }
    }
}

fun void drunkenWalk(int channel)
{
    float gain_buff[8];
    [1,3,5,7,6,4,2,0] @=> int speaker_order[];
    while(dw[channel] == 1)
    {
        Math.randf() => float x;
        Math.randf() => float y;        
        panForPosition(x,y,channel);
//        Math.rand()%8 => int j;
//        0.9791 => gain_buff[speaker_order[(j+1)%8]];
//      0.1034 => gain_buff[speaker_order[(j+2)%8]];
//        0.0593 => gain_buff[speaker_order[(j+3)%8]];
//      0.0466 => gain_buff[speaker_order[(j+4)%8]];
//    0.0438 => gain_buff[speaker_order[(j+5)%8]];
//  0.0484 => gain_buff[speaker_order[(j+6)%8]];
//        0.0649 => gain_buff[speaker_order[(j+7)%8]];
//      0.1285 => gain_buff[speaker_order[(j+8)%8]];        
//    setGain(channel,gain_buff);
       60/((200+rpm[channel]))=>float val;
       val::second=>now;
    }
}

spork ~ getPan();
spork ~getDw();
spork ~getLevel();
spork ~getPosition();
spork ~getFrequency();
1::day => now;