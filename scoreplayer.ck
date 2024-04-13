public class ScorePlayer
{
    EZscore score;
    int pitches[][];
    float rhythms[];

    int n_voices;
    SinOsc oscs[];
    ADSR envs[];
    Gain bus;
    .1 => float mix;
    120 => float local_bpm;

    fun ScorePlayer(EZscore s)
    {
        init(s);
    }

    fun ScorePlayer(EZscore s, float bpm)
    {
        bpm => local_bpm;
        init(s);
    }

    fun ScorePlayer(EZscore s, float bpm, float level)
    {
        level => mix;
        bpm => local_bpm;
        init(s);
    }

    fun void init(EZscore s)
    {
        s @=> score;
        s.n_voices => n_voices;
        s.pitches @=> pitches;
        s.rhythms @=> rhythms;
        init_sound();
    }

    fun void init(EZscore s, float level)
    {
        level => mix;
        s @=> score;
        s.n_voices => n_voices;
        s.pitches @=> pitches;
        s.rhythms @=> rhythms;
        init_sound();
    }

    fun void init_sound()
    {
        SinOsc temp_oscs[n_voices] @=> oscs;
        ADSR temp_envs[n_voices] @=> envs;
        bus.gain(mix);
        for (int i; i < n_voices; i++)
        {
            oscs[i] => envs[i] => bus => dac;
            oscs[i].gain(.5/(n_voices $ float));
            envs[i].set(10::ms, 500::ms, 0.0, 50::ms);
        }
    }

    fun void level(float m)
    {
        m => mix;
        init_sound();
    }
    
    fun void playNote(int which, int note, float duration)
    {
        if(note >= 0)
        {
            Std.mtof(note) => oscs[which].freq;
            envs[which].keyOn();
        }
    }

    fun void play()
    {
        //need to also check that the note and duration streams are the same length
        for(int i; i < pitches.size(); i++)
        {
            for(int j; j < pitches[i].size(); j++)
            {
                spork ~ playNote(j, pitches[i][j], rhythms[i]);
            }
            60*rhythms[i]/local_bpm => float durTime;
            durTime::second => now;
        }
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

}