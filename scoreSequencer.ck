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
master.gain(.5);

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
[@(8, 5, 15), @(8, 25, 1)] @=> vec3 camViews[];
[16.0, 16.0] @=> float camHeight[];
GG.camera().orthographic();
GG.camera().viewSize(camHeight[0]);
GG.camera().pos(camViews[0]);
GG.camera().lookAt(@(8, -1, 0));

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
    vec3 positions[0][0];
    int _nLines;

    // melody variables
    int _size;
    int _notes;
    float durations[];
    int pitches[][];
    float lowP;
    float hiP;
    float dy;
    float dTheta;

    // music
    bpm => float local_bpm;
    int n_voices;
    //SinOsc this_osc;
    SinOsc oscs[];
    //ADSR this_env;
    ADSR envs[];
    Gain bus;
    int playing;
    float totalDuration;
    // follower
    Step step[0]; ADSR height_followers[0];

    fun void init_pos(float r, float h, vec3 origin)
    {
        r => radius;
        h => max_height;
        ringParent.pos(origin);
    }
    fun void init(EZscore input_melody)
    {
        // get data from Melody object
        input_melody @=> m;
        m.durations @=> durations;
        m.pitches @=> pitches;
        m.length => _size;
        m.countNotes() => _notes;
        m.n_voices => n_voices;
        m.totalDuration => totalDuration;
        2*_notes - _size => _nLines;
        init_spheres();
        init_lines();
        init_sound();
        init_followers();

    }

    fun void init_spheres()
    {
        GSphere temp[_notes] @=> spheres;
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

        0 => int sphereIndex;
        for (int i; i < pitches.size(); i++)
        {
            vec3 chordPositions[0];
            pitches[i] @=> int curr_notes[];
            durations[i] * dTheta +=> offset;
            radius * Math.cos(offset) => float xPos;
            radius * Math.sin(offset) => float zPos;
            for (int j; j < curr_notes.size(); j++)
            {
                (curr_notes[j] - lowP) * dy => float yPos;
                if (yPos <= 0) 0 => yPos;
                spheres[sphereIndex].pos(@(xPos, yPos, zPos));
                chordPositions << @(xPos, yPos, zPos);
                sphereIndex++;
            }
            positions << chordPositions;
        }
    }

    fun void init_lines()
    {
        GLines temp[_nLines] @=> lines;
        0 => int lineIndex;
        0 => int sphereIndex;
        // set up lines
        for (auto l : lines)
        {
            l.mat().color(@(0, 0, 0));
            l --> ringParent;
        }
        for(int i; i < _size; i++) // each X-Z position along ring
        {
            pitches[i].size() => int thisChordSize;
            pitches[(i + 1)%_size].size() => int nextChordSize;
            // connect each sphere at this (vertical) position to the bottom sphere of the next position
            for (int p; p < thisChordSize; p++)
            {
                vec3 endpoints[2];
                spheres[(sphereIndex + p) % _notes].pos() => endpoints[0];
                spheres[(sphereIndex + thisChordSize) % _notes].pos() => endpoints[1];
                endpoints => lines[lineIndex].geo().positions;
                (lineIndex + 1) % _nLines => lineIndex;
            }
            // connect the bottom sphere at this position to each sphere in the next position
            for (1 => int q; q < nextChordSize; q++)
            {
                vec3 endpoints[2];
                spheres[sphereIndex].pos() => endpoints[0];
                spheres[(sphereIndex + thisChordSize + q) % _notes].pos() => endpoints[1];
                endpoints => lines[lineIndex].geo().positions;
                (lineIndex + 1) % _nLines => lineIndex;
            }
            sphereIndex + thisChordSize => sphereIndex;
        }
    }

    fun void init_sound()
    {
        SinOsc tempOsc[n_voices] @=> oscs;
        ADSR tempEnv[n_voices] @=> envs; 
        bus.gain(.1);
        for(int i; i < n_voices; i++)
        {
            oscs[i] => envs[i] => bus => master;
            envs[i].set(10::ms, 500::ms, 0.0, 50::ms);
        }
    }

    fun void init_followers()
    {
        Step temp[_notes] @=> step;
        ADSR temp2[_notes] @=> height_followers;
        for(int i; i < _notes; i++)
        {
            height_followers[i].set(20::ms, 400::ms, 0.0, 200::ms);
            //height_followers[i].target((pitches[i] - lowP) * dy);
            step[i] => height_followers[i] => blackhole; 
        }
    }

    fun void playMelody()
    {
        0 => int index;
        //need to also check that the note and duration streams are the same length
        for(int i; i < _size; i++)
        {
            pitches[i] @=> int curr_notes[];
            60*durations[i]/local_bpm => float durTime;
            for(int j; j < curr_notes.size(); j++)
            {
                curr_notes[j] => int note;
                if(note >= 0)
                {
                    //this_osc.gain(1.0);
                    oscs[j].gain(.2);
                    //Std.mtof(note) => this_osc.freq;
                    Std.mtof(note) => oscs[j].freq;
                    //this_env.keyOn();
                    envs[j].keyOn();
                    height_followers[index].keyOn();
                }
                index++;
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
        0 => int sphereIndex;
        0 => int lineIndex;
        0 => int lowestSphere;
        GG.dt() => float dt;  // get delta time
        ringParent.rotateY(-.2 * dt);

        for(int i; i < _size; i++) // each X-Z position along ring
        {
            pitches[i] @=> int curr_notes[];
            pitches[i].size() => int thisChordSize;
            pitches[(i + 1)%_size].size() => int nextChordSize;

            // update sphere positions
            for (int j; j < curr_notes.size(); j++)
            {
                
                ((curr_notes[j] - lowP) * dy) => float yNew;
                if (yNew <= 0) 0 => yNew;
                height_followers[sphereIndex].last() => float env;
                spheres[sphereIndex].posY(yNew/2 + (yNew * env*1.25)/2);
                spheres[sphereIndex].sca(@(.05 + env/10, .05 + env/10, .05 + env/10));
                (sphereIndex + 1) % _notes => sphereIndex;
            }

            // connect each sphere at this (vertical) position to the bottom sphere of the next position
            for (int p; p < thisChordSize; p++)
            {
                vec3 endpoints[2];
                spheres[(lowestSphere + p) % _notes].pos() => endpoints[0];
                spheres[(lowestSphere + thisChordSize) % _notes].pos() => endpoints[1];
                endpoints => lines[lineIndex].geo().positions;
                (lineIndex + 1) % _nLines => lineIndex;
            }
            // connect the bottom sphere at this position to each sphere in the next position
            for (1 => int q; q < nextChordSize; q++)
            {
                vec3 endpoints[2];
                spheres[lowestSphere].pos() => endpoints[0];
                spheres[(lowestSphere + thisChordSize + q) % _notes].pos() => endpoints[1];
                endpoints => lines[lineIndex].geo().positions;
                (lineIndex + 1) % _nLines => lineIndex;
            }
            lowestSphere + thisChordSize => lowestSphere;
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

    //SinOsc theseOsc[];
    //ADSR theseEnv[];
    Gain stackBus;

    0 => float maxDuration;

    fun void init(EZscore m[])
    {
        m.size() => _size;
        m @=> melodies;
        Ring temp[_size] @=> rings;
        //SinOsc tempOsc[_size] @=> theseOsc;
        //ADSR tempEnv[_size] @=> theseEnv;
        init_rings();
        //init_sound();
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
            rings[i].init_pos(r, d, @(0, y, 0));
            rings[i].init(melodies[i]);
            //rings[i].init_sound(theseOsc[i], theseEnv[i], bpm);
            60*(rings[i].totalDuration)/rings[i].local_bpm => float thisDuration;
            if(thisDuration > maxDuration)
            {
                thisDuration => maxDuration;
            }
            rings[i].ringParent --< scene;
            rings[i].ringParent --> stackParent;
        }
    }

    //fun void init_sound()
    //{
    //    for(int i; i < _size; i++)
    //    {
    //        theseOsc[i] => theseEnv[i] => stackBus => master;
    //        theseOsc[i].gain(1/_size);
    //        theseEnv[i].set(10::ms, 500::ms, 0.0, 50::ms);
    //        stackBus.gain(.2);
    //    }
    //}

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
            s.play(24);
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
"[k2s f4:a:du r e:g d:fs c:e d:fs f:a e:g d:fs e:g d:f:a r a b csd d d:f:au d:fs f:a e:g d:fs e:g f:a e:g fs d r]" => string mozart_p;
"[q q sx8 q q e e e e q q sx4 e e e q. h]" => string mozart_r;

// Cello
"[k5s b2 fu es f//fd fu f//bd fu f//fd fu f//b2 fu es f//fd fu f//bd fu f//fd fu es f]" @=> string cello_1_8;
"[q e e q//qx3//qx3//qx3//q e e q//qx3//qx3//q e e q]" @=> string cello_1_8_R;
"[k5s e3 bu a b//bd bu b//e3 bu a b//bd bu b//dd cu bs c//a2 cuu c//g du dn d//dd du d]" @=> string cello_9_16;
"[q e e q//qx3//q e e q//qx3//q e e q//qx3//q e e q//q q q]" @=> string cello_9_16_R;
"[k5s e3 bu a b//bd bu b//ed bu b//bd bu b//dd cu c//a2 cuu c//b2 fu f//bd es es]" @=> string cello_17_24;
"[q e e q//qx3//qx3//qx3//qx3//qx3//qx3//q q q]" @=> string cello_17_24_R;
"[k5s b2 fu f//d au a//g du dn d f//c3 bu b//cd gu g//cd gu g//f cu c//fd cu c]" @=> string cello_25_32;
"[qx3//qx3//q ex4//qx3//qx3//qx3//qx3//q q q]" @=> string cello_25_32_R;
"[k5s b2 fu f//d au a//g du d//c3 bu b//c3 gu g//cd gu g//f cu c//fd cu c]" @=> string cello_33_40;
"[qx3//qx3//qx3//qx3//qx3//qx3//qx3//q q q]" @=> string cello_33_40_R;
"[k5s r r r r r r r r]" @=> string cello_41_48;
"[h.x7 h.]" @=> string cello_41_48_R;
"[k5s r r r r r r r//r e2 gn cn an]" @=> string cello_49_56;
"[h.x7//q e e e e]" @=> string cello_49_56_R;

[cello_1_8, cello_9_16, cello_17_24, cello_25_32, cello_33_40, cello_41_48, cello_49_56] @=> string cello_pitch[];
[cello_1_8_R, cello_9_16_R, cello_17_24_R, cello_25_32_R, cello_33_40_R, cello_41_48_R, cello_49_56_R] @=> string cello_rhythm[];

// Viola
"[k5s r d4 dn d//r d d//r d d//r d d//r d dn d//r d d//r d d//r d dn d]" @=> string viola_1_8;
"[q e e q//qx3//qx3//qx3//q e e q//qx3//qx3//q e e q]" @=> string viola_1_8_R;
"[k5s r r an4 g gn g//r g g//r r g gn f g//r gn g//r r gn f es f//r f f//r r cu cn b cn//r cn cn]" @=> string viola_9_16;
"[e s s e e q//qx3//e s s e e q//qx3//e s s e e q//qx3//e s s e e q//q q q]" @=> string viola_9_16_R;
"[k5s r r r r r r r r]" @=> string viola_17_24;
"[h.x7 h.]" @=> string viola_17_24_R;
"[k5s r r r r r r r r]" @=> string viola_25_32;
"[h.x7 h.]" @=> string viola_25_32_R;
"[k5s r r r r r r r r]" @=> string viola_33_40;
"[h.x7 h.]" @=> string viola_33_40_R;
"[k5s r r cn4 b a b d//g f//r r b4 a g a d//f e//r r an4 g gn g c//e f e d c c dn//d//f e d e f es f g a]" @=> string viola_41_48;
"[e s s ex4//q h//e s s ex4//q h//e s s ex4//ex4 e s s//h.//q sx4 s s s s]" @=> string viola_41_48_R;
"[k5s r r r r r r r r]" @=> string viola_49_56;
"[h.x7 h.]" @=> string viola_49_56_R;

[viola_1_8, viola_9_16, viola_17_24, viola_25_32, viola_33_40, viola_41_48, viola_49_56] @=> string viola_pitch[];
[viola_1_8_R, viola_9_16_R, viola_17_24_R, viola_25_32_R, viola_33_40_R, viola_41_48_R, viola_49_56_R] @=> string viola_rhythm[];

// Violin II
"[k5s r r gn4 f es f//r g g//r a a//r g g//r r gn f es f//r g g//r a a//r g gn g]" @=> string violinII_1_8;
"[e s s e e q//qx3//qx3//qx3//e s s e e q//qx3//qx3//q e e q]" @=> string violinII_1_8_R;
"[k5s r//r e4 d e bu//e r r//r ed d e bu//d r r//r//r//r]" @=> string violinII_9_16;
"[h.//q ex4//qx3//q ex4//qx3//h.//h.//h.]" @=> string violinII_9_16_R;
"[k5s r r an4 g gn g//r g g//r r g gn f gn//r gn gn//r r gn f es f//r f f//r r b a an a//r g g]" @=> string violinII_17_24;
"[e s s e e q//qx3//e s s e e q//qx3//e s s e e q//qx3//e s s e e q//q q q]" @=> string violinII_17_24_R;
"[k5s r r gn4 f es f//r f f//r cnu b cn ef//r gd g//e f g//g a b bs//c d e r fn e//d e c d b c b a]" @=> string violinII_25_32;
"[e s s e e q//qx3//q ex4//qx3//qx3//q q e e//e e q e s s//ex4 s s s s]" @=> string violinII_25_32_R;
"[k5s r r gn4 f es f//r f f//r bs bs//r g4 g//e f g//g a b bs//c d e r bu//c f f]" @=> string violinII_33_40;
"[e s s e e q//qx3//qx3//qx3//qx3//q q e e//e e q e e//q q q]" @=> string violinII_33_40_R;
"[k5s r d5 d//r c bs c gu//r cd c//r b a b fu//r bd b//r a an a eu//r ad a//r an g an d5]" @=> string violinII_41_48;
"[qx3//q ex4//qx3//q ex4//qx3//q ex4//qx3//q e e e e]" @=> string violinII_41_48_R;
"[k5s r d5 d//r c bs c gu//r cd c//r cn b cn f//r b4 b//r a an a c//r b b//r b b]" @=> string violinII_49_56;
"[qx3//q ex4//qx3//q ex4//qx3//q ex4//qx3//q q q]" @=> string violinII_49_56_R;

[violinII_1_8, violinII_9_16, violinII_17_24, violinII_25_32, violinII_33_40, violinII_41_48, violinII_49_56] @=> string violinII_pitch[];
[violinII_1_8_R, violinII_9_16_R, violinII_17_24_R, violinII_25_32_R, violinII_33_40_R, violinII_41_48_R, violinII_49_56_R] @=> string violinII_rhythm[];

// Violin I
"[k5s f5//r//r//r e d e//f//r//r//d e f e a4 b]" @=> string violinI_1_8;
"[h.//h.//h.//q. e e e//h.//h.//h.//e e e e e e]" @=> string violinI_1_8_R;
"[k5s d5 f c cn b//r r a b//d f c cn b//r r b c//a c d e es//f e f//d//r f e a4 b]" @=> string violinI_9_16;
"[q. e e s s//q q e e//q. e e s s//q q e e//h sx4//h e e//h.//q e e e e]" @=> string violinI_9_16_R;
"[k5s d5 f c cn b//r r a b//d f c cn b//r r b c//a r r//f g a c//d//r]" @=> string violinI_17_24;
"[q. e e s s//q q e e//q. e e s s//q q e e//qx3//q q e e//h.//h.]" @=> string violinI_17_24_R;
"[k5s d5 e f//cu a g//f g d//f e d e//c d e//es f g an//a b c r b//a b g a f g f e]" @=> string violinI_25_32;
"[qx3//qx3//qx3//q e e q//qx3//q q e e//e e q e e//ex4 s s s s]" @=> string violinI_25_32_R;
"[k5s d5 b e b fu d//c6 a g f d//f bs4 gu bsd d bs//fu gd eu d e gd//c d e//es f g an//a b c r d//e f5 f es f]" @=> string violinI_33_40;
"[ex6//q ex4//ex6//ex6//qx3//q q e e//e e q e e//q q e s s]" @=> string violinI_33_40_R;
"[k5s g5 r bd//a r gu//f r ad//b//e r b//a b a g c gu//f//an4 g an b c b c d e d e f]" @=> string violinI_41_48;
"[h e e//h e e//h e e//h.//h e e//s s e q e e//h.//sx8 s s s s]" @=> string violinI_41_48_R;
"[k5s g5//a b c g gu//f e d e f//cn6 an b an g du//e r b//a b a g a//b//r an e]" @=> string violinI_49_56;
"[h.//e e q e e//q ex4//q s s e e e//h e e//s s e q q//h.//q q q]" @=> string violinI_49_56_R;

[violinI_1_8, violinI_9_16, violinI_17_24, violinI_25_32, violinI_33_40, violinI_41_48, violinI_49_56] @=> string violinI_pitch[];
[violinI_1_8_R, violinI_9_16_R, violinI_17_24_R, violinI_25_32_R, violinI_33_40_R, violinI_41_48_R, violinI_49_56_R] @=> string violinI_rhythm[];

// Flute
"[k5s r r r r r r r r]" @=> string flute_1_8;
"[h.x7 h.]" @=> string flute_1_8_R;
"[k5s r r r r r//a6 f f e d c//r g bs d g//bs g e f e d bs c]" @=> string flute_9_16;
"[h.x5//ex6//q ex4//e e sx4 e e]" @=> string flute_9_16_R;
"[k5s d6 r g gn//g f e//r gn f//g gn e d e d c b c//a r r//f g a c//d//r]" @=> string flute_17_24;
"[q q e e//h e e//h e e//s s e sx4 e e//qx3//q q e e//h.//h.]" @=> string flute_17_24_R;
"[k5s r r r r r r//r r b6//a b g a f g f e]" @=> string flute_25_32;
"[h.x6//h e e//ex4 s s s s]" @=> string flute_25_32_R;
"[k5s d5 bu d d d dn d//fd du f f f es f//d f gd//b g e d//c d e//es f g an//a b c r d//e esu es]" @=> string flute_33_40;
"[ex4 s s e//ex4 s s e//qx3//q q e e//qx3//q q e e//e e q e e//q q q]" @=> string flute_33_40_R;
"[k5s r r r r r r r r]" @=> string flute_41_48;
"[h.x7 h.]" @=> string flute_41_48_R;
"[k5s b5//c d e c bu//a g f g a//d6 cn dn cn g gnu//g r e//c d c b c e//gn e gn e dn//cn b an gn]" @=> string flute_49_56;
"[h.//e e q e e//q ex4//q s s ex3//h e e//s s e q e e//q s s e q//q q e e]" @=> string flute_49_56_R;

[flute_1_8, flute_9_16, flute_17_24, flute_25_32, flute_33_40, flute_41_48, flute_49_56] @=> string flute_pitch[];
[flute_1_8_R, flute_9_16_R, flute_17_24_R, flute_25_32_R, flute_33_40_R, flute_41_48_R, flute_49_56_R] @=> string flute_rhythm[];

// Tuba
"[k5s r r r r r r r r]" @=> string tuba_1_8;
"[h.x7 h.]" @=> string tuba_1_8_R;
"[k5s r e3 d e//r e e//r e d e//r e e//r d dn d//r d d//r g gn g//r g g]" @=> string tuba_9_16;
"[q e e q//qx3//q e e q//qx3//q e e q//qx3//q e e q//q q q]" @=> string tuba_9_16_R;
"[k5s r e3 d e//r e e//r e d e//r e e//r d dn d//r d d//r d d//r d d]" @=> string tuba_17_24;
"[q e e q//qx3//q e e q//qx3//q e e q//qx3//qx3//q q q]" @=> string tuba_17_24_R;
"[k5s r d3 dn d//r d d//r g gn g b//r e3 e//r c c//r es es//r//r]" @=> string tuba_25_32;
"[q e e q//qx3//q ex4//qx3//qx3//qx3//h.//h.]" @=> string tuba_25_32_R;
"[k5s r d3 dn d//r d d//r g g//r e e//r r r r]" @=> string tuba_33_40;
"[q e e q//qx3//qx3//qx3//h. h. h. h.]" @=> string tuba_33_40_R;
"[k5s e2 g3:b g:b//e2 a3:g4 a3n:gn4 a3:g4 d4:c5//d2 f3:a f:a//d2 f3:an es:g f:an b:e//c2 e3:g e:g//c2 f3:e4 es3:d4 f3:e4 d4:a4//b1 d3:f d:f//cn2 d3:f dn:es d:f an3:d4]" @=> string tuba_41_48;
"[qx3//q ex4//qx3//q ex4//qx3//q ex4//qx3//q e e e e]" @=> string tuba_41_48_R;
"[k5s e2 g3:b g:b//e2 a3:g4 a3n:gn4 a3:g4 d4:c5//d2 f3:a f:a//d2 f3:an es:g f:an an:cn//c2 e3:g e:g//c2 e3:gn d:f e:gn gn:cn//cn2 e3:gn e:gn//cn2 e3 e]" @=> string tuba_49_56;
"[qx3//q ex4//qx3//q ex4//qx3//q ex4//qx3//q q q]" @=> string tuba_49_56_R;

[tuba_1_8, tuba_9_16, tuba_17_24, tuba_25_32, tuba_33_40, tuba_41_48, tuba_49_56] @=> string tuba_pitch[];
[tuba_1_8_R, tuba_9_16_R, tuba_17_24_R, tuba_25_32_R, tuba_33_40_R, tuba_41_48_R, tuba_49_56_R] @=> string tuba_rhythm[];

string lilycove_p[7][0];
string lilycove_r[7][0];

for(int i; i < 7; i++)
{
    [tuba_pitch[i], cello_pitch[i], viola_pitch[i], violinII_pitch[i], violinI_pitch[i], flute_pitch[i]] @=> lilycove_p[i];
    [tuba_rhythm[i], cello_rhythm[i], viola_rhythm[i], violinII_rhythm[i], violinI_rhythm[i], flute_rhythm[i]] @=> lilycove_r[i];
}

EZscore lilycove_measures[7][6];
for(int i; i < 7; i++)
{
    for(int j; j < 6; j++)
    {
        EZscore temp;
        temp.setPitch(lilycove_p[i][j]);
        temp.setRhythm(lilycove_r[i][j]);
        temp @=> lilycove_measures[i][j];
    }
}

//RingStack stack;
//stack.init(lilycove_measures[6]);
//stack.loopPlay();
3 => int N;
RingStack stacks[N];

for(int i; i < N; i++)
{
    RingStack temp;
    temp.init(lilycove_measures[i]);
    temp @=> stacks[i];
}

RingGrid grid;
grid.init(1,N);
for(int i; i < N; i++)
{
    grid.setCell(stacks[i], 0, i);
}

grid.playSequence();

while(true)
{
    1::second => now;
}
