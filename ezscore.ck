///////////////////////////////////////////////////////////////////////
// EZ score: score4-style notation input
///////////////////////////////////////////////////////////////////////
// This file introduces a way to quickly and easily input notes and rhythms,
// based primarily on the SCORE4 system. Pitches and rhythms are assigned
// as strings. These are parsed in the Melody class and interpreted as
// an int array of MIDI notes (pitch) and a float array for rhythms
// (not ChucK rhythms, but beat values).
// 
//
// Alex Han 2023

public class EZscore
{
    // member variables
    0 => int n_voices;
    int length;
    float totalDuration;
    
    int pitches[][];
    float rhythms[];

    //---------------------------------------------------------------------
    // helper functions
    //---------------------------------------------------------------------
    fun string clean_input(string input)
    {
        input.replace("//", " ");
        input.find("[") => int braceL;
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

        0 => int j;
        string out[count+1];

        while(copy.find(delim) != -1)
        {
            copy.find(delim) => int ix;
            copy.substring(0, ix) => string curr;
            curr => out[j];
            copy.substring(ix + 1) => copy;
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
        1 => int tupletDenom;
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
                if(curr == "/" &&  Std.atoi(input.substring((i+1,1))) != 0)
                {
                    Std.atoi(input.substring((i+1,1))) => tupletDenom;
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
            while(dots > 0)
            {
                Math.pow(.5, dots) * value +=> add;
                dots--;
            }
            add +=> value;
        }

        return value/tupletDenom;

    }

    fun string[] handle_repeat(string input)
    {
        string expanded[0];
        input.substring(0, input.find("x")) => string toClone;
        input.substring(input.find("x") + 1) => string toRepeat;
        toRepeat.toInt() => int nTimes;
        for(int i; i < nTimes; i++)
        {
            expanded << toClone;
        }
        return expanded;
    }

    fun float[] parse_rhythm(string raw)
    {
        float output[0];

        split_delim(clean_input(raw), " ") @=> string input[];

        for(int i; i < input.size(); i++)
        {
            // handle repeat flag
            if(input[i].find("x") != -1)
            {
                handle_repeat(input[i]) @=> string repeated[];
                for(auto x : repeated)
                {
                    output << parseDuration(x);
                }
            }
            else
            {
                // handle ties -- add to previous duration
                if(input[i].find("_") != -1)
                {
                    parseDuration(input[i].substring(1)) +=> output[-1];
                }
                // add to rhythm array
                else
                {
                    output << parseDuration(input[i]);
                }
            }
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

    fun int[][] parse_pitch(string input)
    {
        int output[0][0];

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

        for(auto item : split) // for each element in input list
        {
            if(item.find("_") == -1)
            {
                1 => int nTimes;
                if(item.find("x") != -1)
                {
                    item.substring(0, item.find("x")) => string toClone;
                    item.substring(item.find("x") + 1) => string toRepeat;
                    toRepeat.toInt() => nTimes;
                    toClone @=> item;
                }

                int chord[0];
                split_delim(item, ":") @=> string curr_split[];
                for (auto curr : curr_split)
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
                    chord << step + alter + 12*octave;
                }

                if(chord.size() > n_voices)
                {
                    chord.size() => n_voices;
                }

                for(int i; i < nTimes; i++)
                {
                    output << chord;
                }
            }
        }
        return output;
    }
    // midi note to pitch
    ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"] @=> string chromatic[];
    fun string mid2str(int note)
    {
        if(note < 0)
        {
            return "rest";
        }
        else
        {
            note % 12 => int step;
            (note - step) / 12 => int octave;
            chromatic[step] => string name;
            name + Std.itoa(octave) => name;

            return name;
        }
    }

    ///////////////////////////////////////////////////////////////////////
    // API 
    ///////////////////////////////////////////////////////////////////////
    //
    //
    //---------------------------------------------------------------------
    // Constructors
    //---------------------------------------------------------------------

    fun EZscore(string pitches)
    {
        setPitch(pitches);
        float temp[0];
        for(int i; i < length; i++)
        {
            temp << 1.0;
        }
        temp @=> rhythms;
    }

    fun EZscore(string pitches, string rhythms)
    {
        setPitch(pitches);
        setRhythm(rhythms);
    }


    //---------------------------------------------------------------------
    // Basics
    //---------------------------------------------------------------------
    fun void setPitch(string input)
    {
        parse_pitch(input) @=> pitches;
        pitches.size() => length;
    }

    fun void setPitch(string input[])
    {
        int temp[0][0];
        0 => int tempLength;
        for(int i; i < input.size(); i++)
        {
            int thisMeasure[][];
            parse_pitch(input[i]) @=> thisMeasure;
            thisMeasure.size() +=> tempLength;
            for(int j; j < thisMeasure.size(); j++)
            {
                temp << thisMeasure[j];
            }
        }
        temp @=> pitches;
        pitches.size() => length;
    }

    fun void setRhythm(string input)
    {
        parse_rhythm(input) @=> rhythms;
        rhythms.size() => length;
        0 => float sum;
        for(auto i : rhythms)
        {
            i +=> sum;
        }

        sum => totalDuration;
    }
    
    fun void setRhythm(string input[])
    {
        float temp[0];
        0 => int tempLength;
        for(int i; i < input.size(); i++)
        {
            float thisMeasure[];
            parse_rhythm(input[i]) @=> thisMeasure;
            thisMeasure.size() +=> tempLength;
            for(int j; j < thisMeasure.size(); j++)
            {
                temp << thisMeasure[j];
            }
        }
        temp @=> rhythms;
        
        0 => float sum;
        for(auto i : rhythms)
        {
            i +=> sum;
        }

        sum => totalDuration;
    }

    fun int countNotes()
    {
        int count;
        for(int i; i < length; i++)
        {
            pitches[i].size() +=> count;
        }
        return count;
    }

    fun int getLowestNote()
    {
        999 => int lowest;

        for (int i; i < pitches.size(); i++)
        {
            pitches[i] @=> int curr[];
            for (auto x : curr)
            {
                if (x < lowest && x >= 0)
                {
                    x => lowest;
                }
            }

        }

        return lowest;
    }

    fun int getHighestNote()
    {
        -999 => int highest;

        for (int i; i < pitches.size(); i++)
        {
            pitches[i] @=> int curr[];
            for (auto x : curr)
            {
                if (x > highest && x >= 0)
                {
                    x => highest;
                }
            }
        }

        return highest;
    }

    fun void printPitches()
    {
		<<<"# of pitches: ", pitches.size()>>>;
        for (int i; i < pitches.size(); i++)
        {
            pitches[i] @=> int curr[];
            for(auto p : curr)
            {
                <<<p>>>;
            }

        }
    }

    fun void printRhythms()
    {   
		<<<"# of rhythms: ", rhythms.size()>>>;
        for(auto r : rhythms)
        {
            <<<r>>>;
        }
    }

	fun void printPitchRhythm()
	{
		for(int i; i < rhythms.size(); i++)
		{
            pitches[i] @=> int curr[];
            chout <= "note: ";
            for(auto x : curr)
            {
                chout <= mid2str(x) <= " ";
            }
            chout <= IO.newline() <= "duration: " <= rhythms[i] <= IO.newline();
		}
	}
    //---------------------------------------------------------------------
    // Sequence modulators
    //---------------------------------------------------------------------

    // appends the provided sequence to the current one
    fun void add(EZscore seq)
    {
        seq.pitches @=> int newPitches[][];
        seq.rhythms @=> float newDurations[];

        for(int i; i < newPitches.size(); i++)
        {
            pitches << newPitches[i];
        }

        for(int j; j < newDurations.size(); j++)
        {
            rhythms << newDurations[j];
        }
    }

    // transpose each pitch to the "average" of the elementwise intervals 
    // between the pitches in the current sequence and a given sequence
    fun void average(EZscore seq)
    {
        
    }

    // breaks up any chord elements in the sequence into ascending arpeggios with constant duration (quarter note)
    fun void arpeggiate()
    {
        
    }

    // breaks up any chord elements in the sequence into ascending arpeggios with the given rhythmic subdivision
    fun void arpeggiate(float resolution)
    {
        
    }

    // arpeggiates chord elements in the sequence, using the given rhythmic value, in the specified direction 
    // (0 = ascending, 1 = descending, 2 = random order)
    fun void arpeggiate(float resolution, int direction)
    {
        
    }

    // add a voice at a given semitone interval above/below all elements in the sequence
    fun void harmonize(int interval)
    {
        1 +=> n_voices;
        for(int i; i < pitches.size(); i++)
        {
            //<<<pitches[i][pitches[i].size()-1]>>>;
            pitches[i] << pitches[i][pitches[i].size()-1] + interval;
        }
    }

    // add a voice at a given number of diatonic steps according to a given scale
    //fun void harmonize(int interval, int[] scale)
    //{
    //    
    //}

    // insert a new sequence at index 0
    fun void insert(EZscore seq)
    {
        seq.pitches @=> int seqPitches[][];
        seq.rhythms @=> float seqDurations[];

        int tempP[0][0];
        for(int i; i < seqPitches.size(); i++)
        {
            tempP << seqPitches[i];
        }
        for(int j; j < pitches.size(); j++)
        {
            tempP << pitches[j];
        }

        float tempD[0];
        for(int i; i < seqDurations.size(); i++)
        {
            tempD << seqDurations[i];
        }
        for(int j; j < rhythms.size(); j++)
        {
            tempD << rhythms[j];
        }

        tempP @=> pitches;
        tempD @=> rhythms;
    }

    // insert a new sequence at a given index
    fun void insert(EZscore seq, int index)
    {
        seq.pitches @=> int seqPitches[][];
        seq.rhythms @=> float seqDurations[];

        int tempP[0][0];
        for(int j; j < index; j++)
        {
            tempP << pitches[j];
        }
        for(int i; i < seqPitches.size(); i++)
        {
            tempP << seqPitches[i];
        }
        for(index => int j; j < pitches.size(); j++)
        {
            tempP << pitches[j];
        }

        float tempD[0];
        for(int j; j < index; j++)
        {
            tempD << rhythms[j];
        }
        for(int i; i < seqDurations.size(); i++)
        {
            tempD << seqDurations[i];
        }
        for(int j; j < rhythms.size(); j++)
        {
            tempD << rhythms[j];
        }

        tempP @=> pitches;
        tempD @=> rhythms; 
    }

    // inverts the intervals between successive pitches (chromatic)
    fun void invert()
    {
        
    }

    // inverts the intervals between successive pitches, according to a given scale
    //fun void invert(EZscale scale)
    //{
    //   
    //}

    // repeat the sequence a given number of times
    //fun void repeat(int times)
    //{

    //}

    // reverse the order of pitches and rhythms in the sequence
    fun void reverse()
    {
        pitches.reverse();
        rhythms.reverse();
    }

    // reverse the order of either pitches only (layers = 0) and rhythms only (layers = 1),
    // or both (layers = 2)
    fun void reverse(int layers)
    {
        if(layers == 0)
        {
            pitches.reverse();
        }
        if(layers == 1)
        {
            rhythms.reverse();
        }
        if(layers == 2)
        {
            pitches.reverse();
            rhythms.reverse();
        }
        
    }

    // remove elements from the end of the sequence
    fun void shorten(int length)
    {
        pitches.erase(pitches.size()-length, pitches.size());
        rhythms.erase(rhythms.size()-length, rhythms.size());
    }

    // randomize the order of pitches and rhythms in the sequence
    fun void shuffle()
    {
        pitches.shuffle();
        rhythms.shuffle();
    }

    // randomize the order of either pitches only (layers = 0), rhythms only (layers = 1),
    // or both (layers = 2)
    fun void shuffle(int layers)
    {
        if(layers == 0)
        {
            pitches.shuffle();
        }
        if(layers == 1)
        {
            rhythms.shuffle();
        }
        if(layers == 2)
        {
            pitches.shuffle();
            rhythms.shuffle();
        }
    }

    // divides each note into multiple notes, proportionally dividing the duration
    fun void stutter(int times)
    {

    }

    // multiply the rhythmic values in the sequence by the given value 
    // (e.g. passing .5 results in double-time, passing 2 results in half-time)
    fun void subdivide(float subdivision)
    {

    }

    // transpose the sequence by a number of semitones
    fun void transpose(int amount)
    {
        for(int i; i < pitches.size(); i++)
        {
            for(int j; j < pitches[i].size(); j++)
            {
                amount +=> pitches[i][j];
            }
        }
    }

    // transpose the sequence by a number of semitones, starting at a given index
    fun void transpose(int amount, int start)
    {
        for(start => int i; i < pitches.size(); i++)
        {
            for(int j; j < pitches[i].size(); j++)
            {
                amount +=> pitches[i][j];
            }
        }
    }

    // transpose a certain number of notes starting at a given index
    fun void transpose(int amount, int start, int length)
    {
        for(start => int i; i < start + length; i++)
        {
            for(int j; j < pitches[i].size(); j++)
            {
                amount +=> pitches[i][j];
            }
        }
    }

    // trim the sequence to be a specified length in quarter notes
    fun void trim(float length)
    {

    }

}


///////////////////////////////////////////////////////////////////////////////////////
// TO-DO:
// tied notes
// better debugging tools or ways to ensure valid line-up between pitch and rhythm
// measure flags -> force alignment?
// velocity stream
