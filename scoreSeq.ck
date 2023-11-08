///////////////////////////////////////////////////////////////////////
// scoreSequencer - demo for EZ score usage 
///////////////////////////////////////////////////////////////////////
// This is a demonstration of EZ score combined with a graphical sequencer
// made in ChuGL. It shows how melodies can be combined "vertically" to play
// concurrently, as well as sequenced "horizontally" in time. Melodies are visualized
// as "Rings" which can be stacked or placed in a grid. Custom GGens for Rings, 
// RingStack, and RingGrid may be repurposed for score arrangement more generally.
// 
//
// Alex Han 2023

//---------------------------------------------------------------------
// Global playback 
//---------------------------------------------------------------------

140 => float bpm;
(60 / bpm)::second => dur T;
T - (now % T) => now;
Gain master => dac;
master.gain(.25);

//---------------------------------------------------------------------
// ChuGL
//---------------------------------------------------------------------
// set up scene
GG.scene().backgroundColor( @(1,1,1) );
GScene scene;


// Camera settings

// position camera
int camMode;
int camRow;
int camCol;
[0,0] @=> int camFocus[];
[5, 5] @=> int gridSize[];
[@(0, 5, 10), @(0, 50, 1)] @=> vec3 camViews[];
[10.0, 20.0] @=> float camHeight[];
GG.camera().orthographic();
GG.camera().viewSize(camHeight[0]);
GG.camera().pos(camViews[0]);
GG.camera().lookAt(@(0, -1, 0));

// UI elements

UI_Window window;

UI_Button viewToggleButton;
viewToggleButton.text("Toggle camera view");
UI_Button moveCamR;
UI_Button moveCamL;
moveCamR.text("->");
moveCamL.text("<-");
UI_Button moveCamU;
UI_Button moveCamD;
moveCamU.text("^\n|");
moveCamD.text("|\nv");
window.add(viewToggleButton);
window.add(moveCamR);
window.add(moveCamL);
window.add(moveCamU);
window.add(moveCamD);

fun void camHeightButton(UI_Button @ button) 
{
    while (true) {
        button => now;
        <<<"switching camera view">>>;
        camMode++;
        2 %=> camMode;
        GG.camera().pos(camViews[camMode]);
        GG.camera().viewSize(camHeight[camMode]);
        GG.camera().lookAt(@(0, -1, 0));
    }
}

fun void camTranslate(UI_Button @ button) 
{
    while (true) {
        button => now;
        <<<"switching focus">>>;
        if(button == moveCamR)
        {
            camRow++;
            (camFocus[0] + 1) % gridSize[0] => camFocus[0];

        }
        if(button == moveCamL)
        {
            camRow--;
            (camFocus[0] - 1) % gridSize[0] => camFocus[0];
        }
        if(button == moveCamU)
        {
            camCol++;
            (camFocus[1] + 1) % gridSize[1] => camFocus[1];
        }
        if(button == moveCamD)
        {
            camCol--;
            (camFocus[1] - 1) % gridSize[1] => camFocus[1];
        }
        @(camFocus[0]*5, 0, camFocus[1]*5) => vec3 shiftBy;
        GG.camera().pos(camViews[camMode] + shiftBy);
        <<<"Cam position: ", GG.camera().pos()>>>;
        GG.camera().viewSize(camHeight[camMode]);
        GG.camera().lookAt(@(camFocus[0]*5, -1, camFocus[1]*5));
    }
}
spork ~ camHeightButton(viewToggleButton);
spork ~ camTranslate(moveCamR);
spork ~ camTranslate(moveCamL);
spork ~ camTranslate(moveCamU);
spork ~ camTranslate(moveCamD);
//-----------------------------------------------------------------------------

//---------------------------------------------------------------------
// Melody Ring Custom GGen
//---------------------------------------------------------------------
class Ring extends GGen
{
    EZscore m;
    GGen ringParent;
    GSphere spheres[0];
    GLines lines[0];
    ringParent --> scene;

    // graphics variables
    0 => float offset;
    2.5 => float radius;
    1.5 => float max_height;
    vec3 positions[];

    // melody variables
    int _size;
    float durations[];
    int pitches[];
    float lowP;
    float hiP;
    float dy;
    float dTheta;

    // music
    bpm => float local_bpm;
    SinOsc this_osc;
    ADSR this_env;
    int playing;
    float totalDuration;
    // follower
    Step step[0]; ADSR height_followers[0];

    fun void pre_init(float r, float h, vec3 origin)
    {

        r => radius;
        h => max_height;
        ringParent.pos(origin);

    }
    fun void init(EZscore input_melody)
    {
        // get data from Melody object
        input_melody @=> m;
        m.getRhythm() @=> durations;
        m.getPitches() @=> pitches;
        m.getLength() => _size;
        m.getTotalDur()=> totalDuration;
        init_spheres();
        init_lines();
        init_followers();

    }

    fun void init_spheres()
    {
        GSphere temp[_size] @=> spheres;
        // set up sphere objects
        for(auto x : spheres)
        {
            x.mat().polygonMode( Material.POLYGON_FILL );
            x.mat().color(@(0, 0, 0));
            x.sca(@(.05, .05, .05));
            x --> ringParent;
        }

        // position sphere x-direction scaled to rhythmic duration
        2*pi / m.getTotalDur() => dTheta;

        // position sphere y-direction scaled to pitch
        m.getLowestNote() => lowP;
        m.getHighestNote() => hiP;
        max_height / (hiP - lowP) => dy;

        // set sphere positions
        for (int i; i < durations.size(); i++)
        {
            durations[i] * dTheta +=> offset;
            radius * Math.cos(offset) => float xPos;
            radius * Math.sin(offset) => float zPos;
            (pitches[i] - lowP) * dy => float yPos;
            spheres[i].pos(@(xPos, yPos, zPos));
        }

        vec3 t[_size] @=> positions;
        for (auto s : spheres)
        {
            positions << s.pos();
        }
    }

    fun void init_lines()
    {
        GLines temp[_size] @=> lines;
        // set up lines
        for (auto l : lines)
        {
            l.mat().color(@(0, 0, 0));
            l --> ringParent;
        }

        for (int i; i < _size; i++)
        {
            vec3 endpoints[2];
            spheres[i].pos() => endpoints[0];
            spheres[(i + 1) % _size].pos() => endpoints[1];
            endpoints => lines[i].geo().positions;
        }
    }

    fun void init_sound(SinOsc theOsc, ADSR theEnv, float b)
    {
        b => local_bpm;
        theOsc @=> this_osc;
        theEnv @=> this_env;
    }

    fun void init_followers()
    {
        Step temp[_size] @=> step;
        ADSR temp2[_size] @=> height_followers;
        for(int i; i < _size; i++)
        {
            height_followers[i].set(20::ms, 400::ms, 0.0, 200::ms);
            //height_followers[i].target((pitches[i] - lowP) * dy);
            step[i] => height_followers[i] => blackhole; 
        }
    }

    fun void playMelody()
    {
        //need to also check that the note and duration streams are the same length
        for(int i; i < durations.size(); i++)
        {
            pitches[i] => int note;
            60*durations[i]/local_bpm => float durTime;
            if(note >= 0)
            {
                this_osc.gain(1.0);
                Std.mtof(note) => this_osc.freq;
                this_env.keyOn();
                height_followers[i].keyOn();
            }
            durTime::second => now;
        }
    }

    fun void loopMelody()
    {
        while(true)
        {
            spork ~ playMelody();
            60*(totalDuration)/local_bpm => float waitTime;
            waitTime::second => now;
        }
    }
    
    fun void repeatMelody(int repeats)
    {
        for(int i; i < repeats; i++)
        {
            spork ~ playMelody();
            60*(totalDuration)/local_bpm => float waitTime;
            waitTime::second => now;
        }
    }

    fun void update()
    {
        GG.dt() => float dt;  // get delta time
        ringParent.rotateY(-.2 * dt);
        for(int i; i < _size; i++)
        {
            // update sphere positions
            ((pitches[i] - lowP) * dy) => float yNew;
            if (yNew <= 0) 0 => yNew;
            height_followers[i].last() => float env;
            spheres[i].posY(yNew/2 + (yNew * env*1.25)/2);
            spheres[i].sca(@(.05 + env/10, .05 + env/10, .05 + env/10));

            // update line positions
            vec3 endpoints[2];
            spheres[i].pos() => endpoints[0];
            spheres[(i + 1) % _size].pos() => endpoints[1];
            endpoints => lines[i].geo().positions;
        }
    }

    fun void playScene()
    {
        while (true) 
        {
            update();
            GG.nextFrame() => now;
        }
    }
}

class RingStack extends GGen
{

    Ring rings[];
    EZscore melodies[];
    int _size;
    GGen stackParent;
    stackParent --> scene;

    2 => float max_displacement;
    2.5 => float max_radius;
    2 => float max_height;

    SinOsc theseOsc[];
    ADSR theseEnv[];
    Gain stackBus;

    0 => float maxDuration;

    fun void init(EZscore m[])
    {
        m.size() => _size;
        m @=> melodies;
        Ring temp[_size] @=> rings;
        SinOsc tempOsc[_size] @=> theseOsc;
        ADSR tempEnv[_size] @=> theseEnv;
        init_rings();
        init_sound();
    }

    fun void init_rings()
    {
        (max_radius - 1) / (_size - 1) => float radius_spread;
        max_displacement/_size => float d;
        max_height / (_size - 1) => float height_spread;
        for(int i; i < _size; i++)
        {
            1 + (radius_spread*i) => float r;
            max_height/2 - (height_spread*i) => float y;
            rings[i].pre_init(r, d, @(0, y, 0));
            rings[i].init(melodies[i]);
            rings[i].init_sound(theseOsc[i], theseEnv[i], bpm);
            60*(rings[i].totalDuration)/rings[i].local_bpm => float thisDuration;
            if(thisDuration > maxDuration)
            {
                thisDuration => maxDuration;
            }
            rings[i].ringParent --< scene;
            rings[i].ringParent --> stackParent;
        }
    }

    fun void init_sound()
    {
        for(int i; i < _size; i++)
        {
            theseOsc[i] => theseEnv[i] => stackBus => master;
            theseOsc[i].gain(1/_size);
            theseEnv[i].set(10::ms, 500::ms, 0.0, 50::ms);
            stackBus.gain(.2);
        }
    }

    fun void reposition(vec3 location)
    {
        stackParent.pos(location);
    }

    fun void loopPlay()
    {
        for(auto r : rings)
        {
            spork~r.playScene();
            spork~r.loopMelody();
        }
    }

    fun void play(int beats)
    {
        for(auto r : rings)
        {
            spork~r.playScene();
            (60*(r.totalDuration)/r.local_bpm)::second => dur waitTime;
            beats*(T/waitTime) => float N;
            spork~r.repeatMelody(Math.ceil(N)$int);
        }

        beats*T => now;
    }
}

class RingGrid extends GGen
{

    RingStack cells[];
    int _rows;
    int _cols;
    this --> scene;

    int repeatSequence[];

    fun void init(int rows, int cols)
    {
        rows => _rows;
        cols => _cols;
        rows => gridSize[0];
        cols => gridSize[1];
        RingStack temp[_rows*_cols] @=> cells;
    }

    fun void setCell(RingStack stack, int r, int c)
    {
        r*_cols + c => int index;
        stack.stackParent --< scene;
        stack.stackParent --> this;
        stack.reposition(@(c*5, 0, r*5));
        stack @=> cells[index];
    }

    fun void setRepeats(int repeats[])
    {
        repeats @=> repeatSequence;
    }

    fun void playSequence()
    {
        for(auto s : cells)
        {
            s.play(12);
        }
    }
    fun void playSequence(int repeatSeq[])
    {
        while(repeatSeq.size() < cells.size())
        {
            repeatSeq << 0;
        }
        for(int i; i < cells.size(); i++)
        {
            cells[i].play(repeatSeq[i]);
        }
    }
}

//---------------------------------------------------------------------
// Testing
//---------------------------------------------------------------------

// define three simple melodies
["[ef5 d bfd]", "[c4 d ef g]", "[af2 efu bf af g]"] @=> string threePart_p[];
["[q q q]", "[e e e e]", "[q q q q q]"] @=> string threePart_r[];

EZscore threeMelodies[3];
for(int i; i < threeMelodies.size(); i++)
{
    threeMelodies[i].setPitch(threePart_p[i]);
    threeMelodies[i].setRhythm(threePart_r[i]);
}

// define three more simple melodies
["[bf5 bfu]", "[g3 cu d f]", "[af3 bf ef]"] @=> string threePart2_p[];
["[q. q.]", "[q. q. q. q.]", "[h h h]"] @=> string threePart2_r[];
EZscore threeMelodies2[3];
for(int i; i < threeMelodies2.size(); i++)
{
    threeMelodies2[i].setPitch(threePart2_p[i]);
    threeMelodies2[i].setRhythm(threePart2_r[i]);
}

// instantiate a ring stack of first 3 melodies
RingStack stack;
stack.init(threeMelodies);
//stack.loopPlay();

// instantiate a ring stack of ssecond 3 melodies
RingStack stack2;
stack2.init(threeMelodies2);
//stack2.loopPlay();

// instantiate parent grid, place ring stacks in grid
RingGrid grid;
grid.init(2, 2);
grid.setCell(stack, 0, 0);
grid.setCell(stack2, 0, 1);


// play through the grid sequentially
for(int i; i < 4; i++)
{
    grid.playSequence([12, 12]);
}

while(true)
{
    1::second => now;
}
