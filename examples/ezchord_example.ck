/////////////////////////////////////////////////////////////////////////////
// Basic EZchord entry example 
//
// NOTE: requires ezchord.ck to run
//
// Alex Han 2024
/////////////////////////////////////////////////////////////////////////////


string tests[0];
tests << "A"; // unspecified triad assumes major
tests << "Bmin"; // simple triad, no extension
tests << "C##7"; // double accidentals!
tests << "D#dimMaj7"; // explicit maj7 
tests << "Gbaug7#9"; // altered extensions
tests << "Abmaj9#11"; // altered extension, implicit 7th
tests << "Esus13b9"; // altered extension, implicit 7th and 9th
tests << "B7b9#9b13"; // many altered extensions

EZchord chords[tests.size()];



// Print out the contents of each test chord
for(int i; i < tests.size(); i++)
{
    //chords[i].init(tests[i]);
    new EZchord(tests[i], 3) @=> chords[i];
    chout <= chords[i].input <= IO.newline();
    for(auto x : chords[i].notes)
    {
        chout <= x <= " ";
    }
    chout <= IO.newline() <= IO.newline();
}


// Playback for the test chords
Rhodey r => JCRev rev => dac;
.5 => r.gain;
.15 => rev.mix;

for(int i; i < tests.size(); i++)
{
    <<<"test ", i, "(", tests[i],"): ">>>;
    <<<"----------------------------">>>;
    chords[i].notes @=> int ans[];
    for(auto x : ans)
    {
        <<<x>>>;
        Std.mtof(x) => r.freq;
        .5 => r.noteOn;
        100::ms => now;
    }
    <<<"----------------------------">>>;
    800::ms => now;
}