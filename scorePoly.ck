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
[@(0, 5, 10), @(0, 50, 1)] @=> vec3 camViews[];
[7.0, 20.0] @=> float camHeight[];
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

//---------------------------------------------------------------------
// Testing
//---------------------------------------------------------------------
"[k2s f4:a:du r e:g d:fs c:e d:fs f:a e:g d:fs e:g d:f:a r a b csd d d:f:au d:fs f:a e:g d:fs e:g f:a e:g fs d r]" => string mozart_p;
"[q q sx8 q q e e e e q q sx4 e e e q. h]" => string mozart_r;

EZscore melody;
melody.setPitch(mozart_p);
melody.setRhythm(mozart_r);

Ring ring;
ring.init(melody);
spork ~ ring.loopMelody();
spork ~ ring.playScene();

while(true)
{
    1::second => now;
}
