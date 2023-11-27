///////////////////////////////////////////////////////////////////////
// EZ score: score4-style notation input
///////////////////////////////////////////////////////////////////////
// This file introduces a way to quickly and easily input notes and rhythms,
// based primarily on the SCORE4 system. Pitches and rhythms are assigned
// as strings. These are parsed in the Melody class and interpreted as
// an int array of MIDI notes (pitch) and a float array for durations
// (not ChucK durations, but beat values).
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
    float durations[];

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
            while(dots > 0)
            {
                Math.pow(.5, dots) * value +=> add;
                dots--;
            }
            add +=> value;
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
                LH.substring(LH.rfind(" ") + 1) => string temp;
                " " => string toclone;
                toclone.insert(0, temp);
                input.substring(i) => string RH;
                RH.substring(1, RH.find(" ") - 1) => string numStr;
                numStr.toInt() => int num;
                "" => string newstr;
                for (0 => int j; j < num; j++)
                {
                    newstr + toclone => newstr;
                }
                newstr.rtrim() => newstr;
                input.replace(i-(toclone.length()-1), RH.find(" ")+(toclone.length()-1), "");
                input.insert(i-(toclone.length()-1), newstr);
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
            output << chord;
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
        parse_rhythm(input) @=> durations;
        durations.size() => length;
        0 => float sum;
        for(auto i : durations)
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
        temp @=> durations;
        
        0 => float sum;
        for(auto i : durations)
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
		<<<"# of durations: ", durations.size()>>>;
        for(auto r : durations)
        {
            <<<r>>>;
        }
    }

	fun void printPitchRhythm()
	{
		for(int i; i < durations.size(); i++)
		{
            pitches[i] @=> int curr[];
            chout <= "note: ";
            for(auto x : curr)
            {
                chout <= mid2str(x) <= " ";
            }
            chout <= IO.newline() <= "duration: " <= durations[i] <= IO.newline();
		}
	}
}


///////////////////////////////////////////////////////////////////////////////////////
// TO-DO:
// tied notes
// better debugging tools or ways to ensure valid line-up between pitch and rhythm
// measure flags -> force alignment?
// velocity stream
