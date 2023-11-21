MusicXML mXML;

mXML.read("Daisy3.musicxml");

//header is a two dimensional array - retrieves (per part): 
// [0] Instrument Name 
// [1] Midi channel
// [2] Midi program
// [3] Midi volume
// [4] Midi pan
// [5] divisions
// [6] key
// [7] beats 
// [8] beat type
// [9] staves

for(int i; i < mXML.header.cap(); i++)
{
    for(int j; j < mXML.header[i].cap(); j++)
    {
        <<< mXML.header[i][j] >>>;
    }
}

// musicXML retrieves a part-dimensional array of notes(TODO: explain format)

for(int i; i < mXML.score.cap(); i++) // each part
{
    for(int j; j < mXML.score[i].cap(); j++) // each measure
    {
        for(int k; k < mXML.score[i][j].cap(); k++) // each note
        {
            <<< mXML.score[i][j][k] >>>;
        }       
    }
}