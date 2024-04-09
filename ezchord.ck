// ------------------------------------------------------------------
// EZchord : Chord parser
// ------------------------------------------------------------------
// Enter chords as string, get MIDI note numbers out!
// Initialize the EZchord object with a chord name (string)
// parsing is done automatically upon initialization
// then, access member variables to get info about the chord. Most importantly,
// can get the MIDI note values for chord tones
//
// Input: a string, following conventional chord nomenclature
// Ex:
// "Gbmaj7#11" = "G" + "b" + "maj" + "7#11"
// this would correspond to notes Gb Bb Db F Ab C
//
// Member variables:
// _notes (int[]) : MIDI note values for chord tones
// _root (int) : the root note, as MIDI note
// _rootName (str) : name of the root note, e.g. F, Ab, D##
// _triad (int[]) : MIDI note values for the triad component of the chord
// _triadType (str) : the triad type, e.g. "maj", "min", "dim"
// _extension (int[]) : the MIDI note values for the extended (upper) chord tones from the 7th and above
// _suffix (str) : the description of the extension type
//
//
// usage notes:
// input expects the format: pitch + accidental + triad + extension
// pitch is always 1 character, accidental is 0-2 characters, triad is 0 or 3 characters, extension is arbitrarily long
// some extensions assume the presence of unspecified extensions--in example above, Gbmaj7#11 assumes that the 9th (Ab) is also present
//
// See ezchord_test.ck for various test cases
// 
// Alex Han 2023

public class EZchord
{
    // static member variables
    int pitch_dict[7];
    0 => pitch_dict["C"];
    2 => pitch_dict["D"];
    4 => pitch_dict["E"];
    5 => pitch_dict["F"];
    7 => pitch_dict["G"];
    9 => pitch_dict["A"];
    11 => pitch_dict["B"];

    int alter_dict[0];
    -1 => alter_dict["b"];
    1 => alter_dict["#"];

    int triad_dict[0][0];
    [0, 4, 7] @=> triad_dict["dom"];
    [0, 4, 7] @=> triad_dict["maj"];
    [0, 3, 7] @=> triad_dict["min"];
    [0, 4, 8] @=> triad_dict["aug"];
    [0, 3, 6] @=> triad_dict["dim"];
    [0, 5, 7] @=> triad_dict["sus"];
    
    int seventh_dict[0];
    10 => seventh_dict["dom"];
    11 => seventh_dict["maj"];
    10 => seventh_dict["min"];
    10 => seventh_dict["aug"];
    9  => seventh_dict["dim"];
    10 => seventh_dict["sus"];

    // initialization
    string _input;

    // member variables
    int _notes[];
    int _root;
    string _rootName;
    int _triad[];
    string _triadType;
    int _extension[];
    string _suffix;

    fun EZchord(string in)
    {
        in => _input;
        setRoot();
        setTriad();
        setExtension();
        setNotes();        
    }

    fun void init(string in)
    {
        in => _input;
        setRoot();
        setTriad();
        setExtension();
        setNotes();
    }

    fun void setRoot()
    {

        _input => string input;

        int root;
        int alter;

        input.substring(0,1) => string first;
        if(pitch_dict.isInMap(first))
        {
            pitch_dict[first] => root;
            first => _rootName;
        }
        else
        {
            <<<"Invalid root note (did you forget uppercase?)">>>;
            -999 => root;
        }
        input.erase(0, 1);
        if(input.length() > 0)
        {
            input.substring(0,1) => string first;

            if(alter_dict.isInMap(first))
            {
                alter_dict[first] + alter => alter;
                input.erase(0,1);
                if(alter_dict.isInMap(input.substring(0,1)))
                {
                    alter_dict[first] + alter => alter;
                    input.erase(0,1);
                }
            }
        }
        if (alter > 0)
        {
            for (int i; i < alter; i++)
            {
                "#" +=> _rootName;
            }
        }
        if (alter < 0)
        {
            for (int i; i < alter*-1; i++)
            {
                "b" +=> _rootName;
            }   
        }
        root + alter => _root;
    }

    fun void setTriad()
    {
        _input => string input;
        _rootName.length() => int prefix;
        if(_input.length() <= prefix) // i.e. there is nothing after the root characters
        {
            "maj" => _triadType;
            "" => _suffix;
        }
        else
        {
            input.substring(prefix) => input; // trimming the root characters from front
            if(input.length() >= 3)
            {
                input.substring(0,3) => string front;
                if(triad_dict.isInMap(front)) // the first 3 characters match "maj", "min", "dom" etc.
                {
                    front => _triadType;
                    if(input.length() > 3)
                    {
                        input.substring(3) => _suffix; // suffix becomes everything after the root + 3 characters
                    }
                    else
                    {
                        "" => _suffix;
                    }
                }
                else // i.e. extended dom. seventh chords
                {
                    input => _suffix;
                    if(Std.atoi(input.substring(0,1)) != -1) // the first character is some integer
                    {
                        "dom" => _triadType;
                    }
                    else // something is strange, default to major
                    {
                        "maj" => _triadType;
                    }
                }
            }
            if(input.length() > 0 && input.length() < 3) // i.e. extended dom. seventh chords
            {
                input => _suffix; // suffix becomes everything after root 
                if(Std.atoi(input.substring(0,1)) != -1) // first character is some integer
                {
                    "dom" => _triadType;
                }
                else // something is strange, default to major
                {
                    "maj" => _triadType;
                }
            }
        }
        // set integer notes indicating kind of triad
        if(triad_dict.isInMap(_triadType))
        {
            triad_dict[_triadType] @=> _triad;
        }
    }

    fun void setExtension()
    {
        int ans[0];
        0 => int alter;
        _suffix => string input;
        while(input.length() > 0)
        {
            input.substring(0,1) => string first;
            // processing alteration symbol
            if(alter_dict.isInMap(first))
            {
                alter_dict[first] => alter;
                input.erase(0,1);
            }
            // special case -- maj7 explicitly specified 
            if(input.length() >= 4 && input.substring(0,4) == "Maj7")
            {
                ans << seventh_dict["maj"];
                input.erase(0,4);
            }
            // 6th defaults to major 6th above root
            if(first == "6")
            {
                ans << 9 + alter;
            }
            // 7th added depending on triad type
            if(first == "7")
            {
                ans << seventh_dict[_triadType];
                input.erase(0,1);
            }
            // 9th added; if no 7th was specified, adds implicit 7th based on triad
            if(first == "9")
            {
                if(ans.size() == 0)
                {
                    ans << seventh_dict[_triadType];
                }
                ans << 14 + alter;
                input.erase(0,1);
            }
            // 11th added; if no 7th was specified, adds implicit 7th and 9th based on triad
            if(input.length() >= 2 && input.substring(0,2) == "11")
            {
                if(ans.size() == 0)
                {
                    ans << seventh_dict[_triadType];
                    ans << 14;
                }
                ans << 17 + alter;
                input.erase(0,2);
            }
            // 13th added; if no 7th was specified, adds implicit 7th and 9th based on triad. NOTE: does not assume 11th
            if(input.length() >= 2 && input.substring(0,2) == "13")
            {
                //<<<"adding 13th">>>;
                if(ans.size() == 0 && input.length() == 2)
                {
                    ans << seventh_dict[_triadType];
                    ans << 14;
                }
                ans << 21 + alter;
                input.erase(0,2);
            }
        }
        ans @=> _extension;
    }
    fun void setNotes()
    {
        int temp[0];
        for (int i; i < _triad.size(); i++)
        {
            temp << _root + _triad[i];
        }
        if(_extension.size() > 0)
        {
            for (int j; j < _extension.size(); j++)
            {
                temp << _root + _extension[j];
            }
        }

        temp.sort();
        int ans[0];
        if(temp.size() > 0)
        {
            ans << temp[0];
        }
        else
        {
            ans << _root;
        }
        for(1 => int k; k < temp.size(); k++)
        {
            if(temp[k] != temp[k-1])
            {
                ans << temp[k];
            }
        }
        ans @=> _notes;
    }

}