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
// Helper functions
//---------------------------------------------------------------------
fun string clean_input(string input)
{
	input.replace("//", " ");
	<<<input>>>;
    input.find("[") => int braceL;
    input.substring(0, braceL) => string prefix;
    if(prefix != "")
    {
        <<<"key signature: ", prefix>>>;
    }
    input.substring(braceL + 1) => string raw;
    if(!(raw.substring(raw.length()-1,1) == "]") )
    {
        <<<"poorly formatted input - must be surrounded by brackets">>>;
    }
    else
    {
        raw.substring(0, raw.length()-1) => raw;
    }
    return raw;
}


fun string[] split_delim(string input, string delim)
{
    input => string copy;
    0 => int count;

    for(int i; i < copy.length(); i++)
    {
        if(copy.substring(i, 1) == delim)
        {
            count++;
        }
    }
    //count++;
    //<<<count>>>;
    0 => int j;

    string out[count+1];

    while(copy.find(delim) != -1)
    {
        copy.find(delim) => int ix;
        copy.substring(0, ix) => string curr;
        //<<<curr>>>;
        curr => out[j];
        copy.substring(ix + 1) => copy;
        //<<<copy>>>;
        j++;
    }
    if (copy.length() > 0) 
    {
        copy => out[j];
    }


    return out;
}
//---------------------------------------------------------------------
/// RHYTHM PARSING
//---------------------------------------------------------------------
["s", "e", "q", "h", "w"] @=> string durationLabels[];
[.25, .5, 1.0, 2.0, 4.0] @=> float durationVals[];
float durationMap[5];
for (int i; i< durationVals.size(); i++)
{
    durationVals[i] => durationMap[durationLabels[i]];
}

fun float parseDuration(string input)
{
    0 => int dots;
    0 => int isTriplet;
    float value;

    if(Std.atof(input) != 0)
    {
        Std.atof(input) => value;
    }
    else
    {
        for(int i; i < input.length(); i++)
        {
            input.substring((i,1)) => string curr;
            if(curr == "t")
            {
                1 => isTriplet;
            }        
            if(curr == ".")
            {
                dots++;
            }
            if(curr == "s" || curr == "e" || curr == "q" || curr == "h" || curr == "w")
            {
                durationMap[curr] => value;
            }
        }
        if(isTriplet == 1)
        {
            value * 2/3 => value;
        }
        0 => float add;
        if(dots > 0)
        {
            for(int i; i < dots + 1; i++)
            {
                value*Math.pow(.5, i) +=> add;
            }
            value * add => value;
        }
    }

    return value;

}
fun float[] parse_rhythm(string raw)
{
    clean_input(raw) => string input;
    for(int i; i < input.length(); i++)
    {
        if(input.substring(i, 1) == "x")
        {
            input.substring(0, i) => string LH;
            //<<<"LH: ", LH>>>;
            LH.substring(LH.rfind(" ") + 1) => string temp;
            //<<<"to clone: ", temp, " length: ", temp.length()>>>;
            " " => string toclone;
            toclone.insert(0, temp);
            //<<<"to clone (w space): ", toclone, " length: ", toclone.length()>>>;
            input.substring(i) => string RH;
            //<<<"RH: ", RH>>>;
            RH.substring(1, RH.find(" ") - 1) => string numStr;
            numStr.toInt() => int num;
            //<<<"num: ", num>>>;
            "" => string newstr;
            for (0 => int j; j < num; j++)
            {
                newstr + toclone => newstr;
            }
            newstr.rtrim() => newstr;
            //<<<"newstr: ", newstr>>>;
            input.replace(i-(toclone.length()-1), RH.find(" ")+(toclone.length()-1), "");
            //<<<"trimmed input: ", input>>>;
            input.insert(i-(toclone.length()-1), newstr);
            //<<<"with inserted newstr: ", input>>>;
        }
    }
    split_delim(input, " ") @=> string strOut[];
    float output[0];
    for(auto i : strOut)
    {
        output << parseDuration(i);
    }
    return output;
}
//---------------------------------------------------------------------
/// PITCH PARSING
//---------------------------------------------------------------------
["c", "d", "e", "f", "g", "a", "b", "r"] @=> string base_pitches[];
[12, 14, 16, 17, 19, 21, 23, -999] @=> int base_notes[];
int pitch_map[7];

for (int i; i < base_pitches.size(); i++)
{
    base_notes[i] => pitch_map[base_pitches[i]];
}

fun int[] getKeyVector(string key)
{
    int keyVector[7];
    keyVector.zero();

    if(key.length() == 3)
    {
        key.substring(2,1) => string type;
        Std.atoi(key.substring(1,1)) => int n;
        //<<<"type: ", type, " n: ", n>>>;

        if(type == "s")
        {
            for(int i; i < n; i++)
            {
                1 => keyVector[i];
            }
        }
        if(type == "f")
        {
            for(7 - n => int i; i < 7; i++)
            {
                -1 => keyVector[i];
            }
        }
    }

    return keyVector;
}

fun int[] parse_pitch(string input)
{
    int output[0];

    // extract key signature information
    split_delim(clean_input(input), " ") @=> string split[];
    int keyVector[7];
    keyVector.zero();
    if(split[0].substring(0,1) == "k")
    {
        getKeyVector(split[0]) @=> keyVector;  // return the vector of alters
        split.erase(0);
    }

    // build associative array: key = pitch (string), value = alter (-1, 0, or 1)
    ["f", "c", "g", "d", "a", "e", "b"] @=> string circleFifths[];
    int key[0];
    for (int i; i < 7; i++)
    {
        keyVector[i] => key[circleFifths[i]];
    }
    4 => int octave;
    999 => int last;

    for(auto curr : split) // for each element in input list
    {
        0 => int step;
        0 => int alter;
        int pitch;
        0 => int octFlag;
        0 => int dirFlag;
        // future: need to check if "first" is indeed a valid pitch/step
        curr.substring(0,1) => string first;
        pitch_map[first] => step;
        if(key.isInMap(first)) 
        {
            key[first] => alter; // apply key signature from key vector
        }
        curr.erase(0,1);
        step + alter => pitch;
        if(curr.length() == 0 && pitch > 0) // if no more flags after step/alter, check proximity for octave
        {
            if(pitch - last > 6)
            {
                //octave--;
            }
            if(pitch - last <= -6)
            {
                //octave++;
            }
        }
        while(curr.length() > 0) // go through each character in element
        {
            curr.substring(0,1) => first;
            //handle alter flag if there
            if(first == "f")
            {
                -1 => alter;
            }
            if(first == "s")
            {
                1 => alter;
            }
            if(first == "n")
            {
                0 => alter;
            }
            // handle explicit octave number flag
            if(first.toInt() != 0)
            {
                Std.atoi(first) => octave;
                1 => octFlag;
            }
            // handle interval direction flags (octave flag overrides)
            if(first == "u" && octFlag == 0)
            {
                if(pitch - last <= 6)
                {
                    octave++;
                }
                1 => dirFlag;
            }
            if(first == "d" && octFlag == 0)
            {
                if(pitch - last > -6)
                {
                    octave--;
                }
                1 => dirFlag;
            }
            curr.erase(0,1);
        }
        // set octave based on proximity--tritone always favors higher octave
        // direction flag (and octave flag) overrides
        if (octFlag == 0 && dirFlag == 0 && pitch > 0)
        {
            if(pitch - last > 6)
            {
                octave--;
            }
            if(pitch - last <= -6)
            {
                octave++;
            }
        }
        if (step > 0)
        {
            step + alter => last;
        }
        output << step + alter + 12*octave;
    }
    return output;
}

//---------------------------------------------------------------------
// Melody Class
//---------------------------------------------------------------------

class Melody
{
    int n_voices;
    int length;
    float totalDuration;
    
    int pitches[];
    float durations[];

    fun void setPitch(string input)
    {
        parse_pitch(input) @=> pitches;
        pitches.size() => length;
    }
    fun void setRhythm(string input)
    {
        parse_rhythm(input) @=> durations;
        durations.size() => length;
        0 => float sum;
        for(auto i : durations)
        {
            i +=> sum;
        }

        sum => totalDuration;
    }

    fun int getLength()
    {
        return length;
    }

    fun float getTotalDur()
    {
        return totalDuration;
    }
    fun int[] getPitches()
    {
        return pitches;
    }
    fun float[] getRhythm()
    {
        return durations;
    }

    fun int getLowestNote()
    {
        999 => int lowest;

        for (auto x : pitches)
        {
            if (x < lowest && x >= 0)
            {
                x => lowest;
            }
        }

        return lowest;
    }
    fun int getHighestNote()
    {
        -999 => int highest;

        for (auto x : pitches)
        {
            if (x > highest && x >= 0)
            {
                x => highest;
            }
        }

        return highest;
    }

    fun void printPitches()
    {
		<<<"# of pitches: ", pitches.size()>>>;
        for(auto p : pitches)
        {
            <<<p>>>;
        }
    }
    fun void printRhythms()
    {   
		<<<"# of durations: ", durations.size()>>>;
        for(auto r : durations)
        {
            <<<r>>>;
        }
    }

	fun void printBoth()
	{
		for(int i; i < durations.size(); i++)
		{
			<<<"note: ", pitches[i], ", duration: ", durations[i]>>>;
		}
	}
}


//---------------------------------------------------------------------
// Global playback 
//---------------------------------------------------------------------

140 => float bpm;
(60 / bpm)::second => dur T;
T - (now % T) => now;
Gain master => dac;
master.gain(.25);


//-----------------------------------------------------------------------------
// ChuGL

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
    Melody m;
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
    fun void init(Melody input_melody)
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
    Melody melodies[];
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

    fun void init(Melody m[])
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

Melody threeMelodies[3];
for(int i; i < threeMelodies.size(); i++)
{
    threeMelodies[i].setPitch(threePart_p[i]);
    threeMelodies[i].setRhythm(threePart_r[i]);
}

// define three more simple melodies
["[bf5 bfu]", "[g3 cu d f]", "[af3 bf ef]"] @=> string threePart2_p[];
["[q. q.]", "[q. q. q. q.]", "[h h h]"] @=> string threePart2_r[];
Melody threeMelodies2[3];
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
