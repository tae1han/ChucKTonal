/////////////////////////////////////////////////////////////////////
// ChucK-Tonal 
// some basic classes
/////////////////////////////////////////////////////////////////////

//-------------------------------------------------------------------
// Static definitions
//-------------------------------------------------------------------
["C","D","E","F","G","A","B"] @=> string pitchTypes[];
["C","Db","D","Eb","E","F","Gb","G","Ab","A","Bb","B"] @=> string chromatic[];
[0, 2, 4, 5, 7, 9, 11] @=> int pitchClassBase[];
["bb","b","#","##"] @=> string accidentalTypes[];
[-2, -1, 1, 2] @=> int accidentalVals[];
["whole", "w", "half", "h", "quarter", "q", "eighth", "e", "8th", "sixteenth", "s", "16th", "32nd"] @=> string beatDurs[];
[1, 1, 2, 2, 4, 4, 8, 8, 8, 16, 16, 16, 32] @=> int beatSubDivs[];
//-------------------------------------------------------------------
// BPM is globally set, should be per score
160 => float bpm;
// Summary

// Pitch = step, accidental, octave
// Note = pitch & duration
// Measure = stream of notes
// Part = stream of measures
// Score = collection of parts 

//-------------------------------------------------------------------
// Pitch
//-------------------------------------------------------------------
class Pitch
{
    string step;
    int alter;
    int octave;

    string name;
    int pitchClass;

    fun void set(string s, int a, int o)
    {
        s => step;
        a => alter;
        o => octave;

        string acc;

        for(int i; i < accidentalVals.size(); i++)
        {
            if(a==accidentalVals[i])
            {
                accidentalTypes[i] => acc;
            }
        }
        step + acc + Std.itoa(o) => name;
        setPitchClass();
    }

    fun void set(string p) // All-in-one
    {
        p.upper().charAt(0) => int first;
        p.substring(1, p.length()-2) => string middle;
        p.charAt(p.length()-1) => int last;

        if(first >= 'A' && last <= 'G')
        {
            p.substring(0,1).upper() => step;
        }
        else
        {
            "C" => step;
        }

        if(last >= '0' && last <= '9')
        {
            last - 48 => octave;
        }
        else
        {
            4 => octave;
        }
        
        if(middle.length() > 0)
        {
            for(int i; i < accidentalTypes.size(); i++)
            {
                if(middle == accidentalTypes[i])
                {
                    accidentalVals[i] => alter;
                }
            }
        }
        else
        {
            0 => alter;
        }

        p => name;
        setPitchClass();
    }

    fun void setPitchClass()
    {
        for(int i; i < pitchTypes.size(); i++)
        {
            if(step == pitchTypes[i])
            {
                pitchClassBase[i] + alter => pitchClass;
                if(pitchClass < 0)
                {
                    12 +=> pitchClass;
                }
            }
        }
        //return pitchClass;
    }

    fun int ptom()
    {
        return pitchClass + 12*octave + 12;
    }

    fun float ptof()
    {
        return Std.mtof(pitchClass + 12*octave + 12);
    }


    fun void transpose(int t) // in semitones, signed up/down
    {
        t % 12 => int amt;
        (t - amt) / 12 => int oct;
        (pitchClass + amt) % 12 => int newPC;
        if((pitchClass + amt) > 12)
        {
            octave++;
        }
        octave + oct => octave;
        chromatic[newPC] + Std.itoa(octave) => name;
        set(name);
         
    }
    fun void details()
    {
        chout <= "Note data summary: " <= IO.newline()
        <= "Name: " <= name <= IO.newline()
        <= "Pitch: " <= step <= IO.newline()
        <= "Octave: " <= octave <= IO.newline()
        <= "Accidental: " <= alter <= IO.newline()
        <= "Pitch class: " <= pitchClass <= IO.newline();
    }
}
//-------------------------------------------------------------------
// Note
//-------------------------------------------------------------------

class Note
{
    Pitch p;
    float duration;

    string step;
    int alter;
    int octave;

    string name;
    int pitchClass;

    // graphical stuff
    int voice;
    string type;
    int stem;

    fun void set(Pitch pObj, string d)
    {
        pObj @=> p;
        setBeatDur(d);
        linkPitch();
    }
    fun void set(Pitch pObj, float d)
    {
        pObj @=> p;
        d => duration;
        linkPitch();
    }

    fun void set(string pStr, string d)
    {
        p.set(pStr);
        setBeatDur(d);
        linkPitch();
    }
    fun void set(string pStr, float d)
    {
        p.set(pStr);
        d => duration;
        linkPitch();
    }

    fun void setBeatDur(float b)
    {
        b => duration;
    }
    fun void setBeatDur(string b)
    {
        string s;
        float val;
        0 => int dots;
        for(int i; i < b.length(); i++)
        {
            if (b.charAt(i) == 46)
            {
                dots++;
            }
            else
            {
                b.substring(i,1) +=> s;
            }
        }
        for(int i; i < beatDurs.size(); i++)
        {
            if(s == beatDurs[i])
            {
                4.0 / beatSubDivs[i] => val;
            }
        }
        1.0 => float extra;
        for(1 => int k; k <= dots; k++)
        {
            Math.pow(.5, k) +=> extra;
        }

        val * extra => duration;
    }

    fun void linkPitch()
    {
        p.name => name;
        p.step => step;
        p.alter => alter;
        p.pitchClass => pitchClass;

    }

    fun void transpose(int t)
    {
        p.transpose(t);
        linkPitch();
    }

    fun void details()
    {
        chout <= "Note data summary: " <= IO.newline()
        <= "Name: " <= p.name <= IO.newline()
        <= "Pitch: " <= p.step <= IO.newline()
        <= "Octave: " <= p.octave <= IO.newline()
        <= "Duration in beats: " <= duration <= IO.newline()
        <= "Accidental: " <= p.alter <= IO.newline()
        <= "Pitch class: " <= p.pitchClass <= IO.newline();
    }
}

//-------------------------------------------------------------------
// Measure
//-------------------------------------------------------------------

class Measure
{
    int divisions;
    int keysig[2];
    int timesig[2];

    // graphical stuff
    string clef;
    int staves;

    Note notes[];
    Note notesXML[][];

    int index;
    Part parentPart;

    fun void attributes( int k[], int t[], int d)
    {
        k @=> keysig;
        t @=> timesig;
        d => divisions;
    }
    fun void addMeasureXML(string m[]) 
    {
        Note temp[0][0];
        m.size() => temp.size;
        for (int i; i < m.size(); i++)
        {
            str2notes(m[i]) @=> temp[i];
        }

        temp @=> notesXML;
    }
    // for writing new music -- ignore these functions for now
    fun void addNote(Note n) //add Note object
    {

        if(notes.size() == 0)
        {
            [n] @=> notes;
        }
        else
        {
            Note temp[notes.size()+1];
            for(int i; i < notes.size(); i++)
            {
                notes[i] @=> temp[i];
            }
            n @=> temp[notes.size()];

            temp @=> notes;
        }

    }

    fun void addNote(string name, string d)
    {
        Note n;
        n.set(name, d);

        Note temp[notes.size()+1];
        for(int i; i < notes.size(); i++)
        {
            notes[i] @=> temp[i];
        }
        n @=> temp[notes.size()];

        temp @=> notes;
    }

    fun void addNotes(string names[], string durations[])
    {
        if(names.size() != durations.size())
        {
            chout <= "ERROR: number of notes and durations should be same" <= IO.newline();
        }
        else
        {
            for(int i; i < names.size(); i++)
            {
                addNote(names[i], durations[i]);
            }
        }
    }

    fun void printNotes()
    {
        for(int i; i<notes.size();i++)
        {
            chout <= " " <= notes[i].name;
        }
        chout <= IO.newline();
    }
    //---------------------------------------------------------------

    fun void play()
    {
        parentPart.playMeasure(notesXML, index);
    }

}

//-------------------------------------------------------------------
// Part
//-------------------------------------------------------------------

class Part
{
    string partID;
    int startIndex;
    0 => int max_voices;
    TriOsc gens[];
    ADSR envs[]; 
    Gain bus;

    string measures[][];
    Measure measuresXML[];
    Score parentScore;

    fun void set(string part[][])
    {
        countVoices(part);
        initSound();
        //part @=> measures;
        addMeasuresXML(part);
    }

    fun void addMeasuresXML(string part[][])
    {
        Measure temp[0];
        part.size() => temp.size;
        for (int i; i < part.size(); i++)
        {
            Measure curr;
            curr.addMeasureXML(part[i]);
            curr @=> temp[i];
        }

        temp @=> measuresXML;

        for (int j; j < measuresXML.size(); j++)
        {
            this @=> measuresXML[j].parentPart;
            j => measuresXML[j].index;
        }
    }

    fun void countVoices(string part[][])
    {
        1 => int pMax;

        for(int i; i <  part.size(); i++)
        {
            part[i] @=> string m[];
            1 => int mMax;
            for(int j; j < m.size(); j++)
            {
                1 => int cMax;
                m[j] => string s;
                for(int k; k < s.length(); k++)
                {
                    if(s.charAt(k) == '&')
                    {
                        cMax++;
                    }
                }
                if(cMax > mMax)
                {
                    cMax => mMax;
                }
            }
            if(mMax > pMax)
            {
                mMax => pMax;
            }
        }

        pMax => max_voices;
    }

    fun void initSound()
    {
        if(max_voices == 0)
        {
            chout <= "ERROR: number of voices not set (use countVoices)" <= IO.newline();
        }
        else
        {
            TriOsc newGens[max_voices];
            ADSR newEnvs[max_voices];
            for(int i; i < max_voices; i++)
            {
                0.0 => newGens[i].gain;
                newEnvs[i].set( 50::ms, 800::ms, 0, 120::ms);
                newGens[i] => newEnvs[i];
            }
            newGens @=> gens;
            newEnvs @=> envs;
        }

        connect();
    }

    fun void connect()
    {
        for(int i; i < gens.size(); i++) {
            gens[i] => envs[i] => bus;
        }
        .2 => bus.gain;
        chout <= "Connecting part to dac: " <= partID <= IO.newline();
        bus => dac;
    }

    fun void disconnect()
    {
        chout <= "Disconnecting part from dac: " <= partID <= IO.newline();
        bus =< dac;
    }

    fun dur getNotesDuration(Note notes[]) 
    {
        0 => float maxDur;
        for(int i; i < notes.size(); i++)
        {
            notes[i].duration => float curr;
            if (curr > maxDur) {
                curr => maxDur;
            }
        }
        (60/bpm)*maxDur::second => dur T;

        return T;
    }

    fun void playNotes(Note notes[]) 
    {
        for(int i; i < notes.size(); i++)
        {
            spork ~ playNote(notes[i], i);
            me.yield();
        }
    }

    fun void playNote(Note note, int which)
    {
        note.p @=> Pitch pitch;
        //pitch.details();
        (60/parentScore.bpm)*note.duration::second => dur T;
        pitch.ptof() => gens[which].freq;
        if(pitch.step == "R")
        {
            gens[which].gain(0);
        }
        else
        {
            gens[which].gain(.2);
        }
        //.05/max => gens[which].gain;
        envs[which].keyOn();
        chout <= "playing note " <= note.name <= ": " <= pitch.ptof() <= "Hz on voice " <= which <= IO.newline();
        T => now;
        envs[which].keyOff();
        //me.yield();
    }

    fun void playMeasure(Note notes[][], int which) 
    {
        for (int i; i < notes.size(); i++) 
        {
            playNotes(notes[i]);
            getNotesDuration(notes[i]) => now;
        }
    }
    
    fun void play() 
    {
        for (int i; i < measuresXML.size(); i++)
        {
            measuresXML[i].notesXML @=> Note notes[][];
            for (int j; j < notes.size(); j++) 
            {
                playNotes(notes[j]);
                getNotesDuration(notes[j]) => now;
            }
        }
    }
}

//-------------------------------------------------------------------
// Score
//-------------------------------------------------------------------

class Score
{
    Part parts[0];
    float bpm;
    
    fun void fromXML(string header[][], string rawData[][][]) 
    {
        0 => int n_parts;
        for(int i; i < header.size(); i++)
        {
            Std.atoi(header[i][9]) +=> n_parts;
        }
        n_parts => parts.size;

        string splitData[][][];

        -1 => int filled;

        for (int j; j < header.size(); j++)
        {
            string temp[][][];
            Std.atoi(header[j][9]) => int nStaves;
            splitPartStaves(rawData[j], nStaves) @=> temp;
            for (int k; k < nStaves; k++)
            {
                parts[filled + 1].set(temp[k]);
                filled + 1 => parts[filled + 1].startIndex;
                filled++;
            }
        }
    }

    // Split a multi-staff part into array of parts
    fun string[][][] splitPartStaves(string data[][], int nStaves) 
    {
        string splitData[0][0][0];
        nStaves => splitData.size;
        
        if (data.size() % nStaves != 0) {
            <<<"XML Read Error: unbalanced measures - each staff in part should have same number of measures.">>>;
        }

        0 => int which;
        data.size() / nStaves => int nBars;
        for (int i; i < nStaves; i++) 
        {
            string currPartData[0][0];
            nBars => currPartData.size;
            for (int j; j < nBars; j++)
            {
                data[i + (j * nStaves)] @=> currPartData[j];
            }
            currPartData @=> splitData[i];
        }

        return splitData;
    }
    fun void play() 
    {
        for (int i; i < parts.size(); i++) {
            spork ~ parts[i].play();
        }
    }
    fun void print() 
    {
        for(int i; i < parts.size(); i++) {
            chout <= "Part number " <= i <= " (" <= parts[i].partID <= "):" <= IO.newline();
            chout <= "-------------------------" <= IO.newline();
            parts[i].measuresXML @=> Measure measures[];
            for(int j; j < measures.size(); j++) {
                chout <= "Measure number " <= j <=":" <= IO.newline();
                chout <= "-------------------------" <= IO.newline();
                measures[j].notesXML @=> Note notes[][];
                for(int k; k < notes.size(); k++) {
                    notes[k] @=> Note elem[];
                    chout <= "Position: " <= k <= IO.newline();
                    chout <= "-------------------------" <= IO.newline();
                    for(int l; l < elem.size(); l++) {
                        elem[l].details();
                        chout <= IO.newline();
                        //chout <= elem[l].name <= elem[l].octave <= ", duration = " <= elem[l].duration <= IO.newline();
                    }
                }
            }
        }
    }
}

/////////////////////////////////////////////////////////////////////
// XML Parsing
/////////////////////////////////////////////////////////////////////

fun Note str2note(string s)
{
    s.substring(0, 1) => string step;
    s.substring(1, 1) => string alter;
    s.substring(2, 1) => string oct;
    s.substring(3, 1) => string duration;

    Pitch p;
    Note n;
    p.set(step, Std.atoi(alter), Std.atoi(oct));
    n.set(p, Std.atof(duration));

    return n;
}

fun Note[] str2notes(string s)
{
    s => string sCopy;
    1 => int count;
    for(int i; i < s.length(); i++)
    {
        if(s.charAt(i) == '&')
        {
            count++;
        }
    }

    Note notes[count];
    for(int i; i < notes.size(); i++)
    {
        sCopy.substring(5*i, 4) => string sub;
        str2note(sub) @=> notes[i];
    }

    return notes;
}

// Split a multi-staff part into array of parts
fun string[][][] splitPartStaves(string data[][], int nStaves) 
{
    string splitData[0][0][0];
    nStaves => splitData.size;
    
    if (data.size() % nStaves != 0) {
        <<<"XML Read Error: unbalanced measures - each staff in part should have same number of measures.">>>;
    }

    0 => int which;
    data.size() / nStaves => int nBars;
    for (int i; i < nStaves; i++) 
    {
        string currPartData[0][0];
        nBars => currPartData.size;
        for (int j; j < nBars; j++)
        {
            data[i + (j * nStaves)] @=> currPartData[j];
        }
        currPartData @=> splitData[i];
    }

    return splitData;
}

// Parse XML data into Score object
fun Score parseXML(string header[][], string rawData[][][], float bpm) 
{
    0 => int n_parts;
    for(int i; i < header.size(); i++)
    {
        Std.atoi(header[i][9]) +=> n_parts;
    }
    Score score;
    bpm => score.bpm;
    Part parts[n_parts] @=> score.parts;

    -1 => int filled;

    for (int j; j < header.size(); j++)
    {
        string temp[][][];
        Std.atoi(header[j][9]) => int nStaves;
        splitPartStaves(rawData[j], nStaves) @=> temp;
        for (int k; k < nStaves; k++)
        {
            score.parts[filled + 1].set(temp[k]);
            score @=> score.parts[filled + 1].parentScore;
            filled + 1 => parts[filled + 1].startIndex;
            if (nStaves > 1)
            {
                header[j][0] + Std.itoa(k) => parts[filled + 1].partID;
            }
            filled++;
        }
    }

    return score;

}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
// Testing zone
//////////////////////////////////////////////////////////////////////////////////////////////////////////
[["Piano", "0", "0", "1", "0", "1", "Gmajor", "3", "4", "2"], 
["Acoustic Bass", "0", "0", "1", "0", "1", "Gmajor", "3", "4", "1"]] @=> string testHeader[][];

[[["D051", "C151", "D051"], ["G021", "D031&B031", "D031&B031"],["B041", "A041", "G041"],["B021", "D031&B031", "D031&B031"],
 ["A042", "F141"], ["D031", "F131&A031", "F131&A031"],["D042", "R001"], ["A021", "F131&A031", "F131&A031"]],
[["G013"], ["D013"], ["D013"], ["A013"]]] @=> string testData[][][];


parseXML(testHeader, testData, 160) @=> Score score;
score.print();
score.play();

while(true)
{
    1::second => now;
}
