#include <windows.h>
    #include <mmsystem.h>
   
int main() {
    MMRESULT rc;              // Return code.
    HMIXER hMixer;            // Mixer handle used in mixer API calls.
    MIXERCONTROL mxc;         // Holds the mixer control data.
    MIXERLINE mxl;            // Holds the mixer line data.
    MIXERLINECONTROLS mxlc;   // Obtains the mixer control.

    // Open the mixer. This opens the mixer with a deviceID of 0. If you
    // have a single sound card/mixer, then this will open it. If you have
    // multiple sound cards/mixers, the deviceIDs will be 0, 1, 2, and
    // so on.
    rc = mixerOpen(&hMixer, 0,0,0,0);
    if (MMSYSERR_NOERROR != rc) {
        // Couldn't open the mixer.
      printf("bad4");
    }

    // Initialize MIXERLINE structure.
    ZeroMemory(&mxl,sizeof(mxl));
    mxl.cbStruct = sizeof(MIXERCONTROL);

    // Specify the line you want to get. You are getting the input line
    // here. If you want to get the output line, you need to use
    // MIXERLINE_COMPONENTTYPE_SRC_WAVEOUT.
    // MIXERLINE_COMPONENTTYPE_DST_WAVEIN
    // MIXERLINE_COMPONENTTYPE_DST_SPEAKERS
    
    mxl.dwComponentType = MIXERLINE_COMPONENTTYPE_DST_SPEAKERS;

    rc = mixerGetLineInfo((HMIXEROBJ)hMixer, &mxl,
                           MIXER_OBJECTF_HMIXER |
						   MIXER_GETLINEINFOF_COMPONENTTYPE);
    if (MMSYSERR_NOERROR != rc) {
        // Couldn't get the mixer line.
      printf("bad3 got %d are %d %d %d %d %d", rc,MIXERR_INVALLINE,MMSYSERR_BADDEVICEID,MMSYSERR_INVALFLAG,MMSYSERR_INVALHANDLE,MMSYSERR_INVALPARAM);
    }
    
      // Get the control.
      ZeroMemory(&mxlc, sizeof(mxlc));
      mxlc.cbStruct = sizeof(MIXERCONTROL);
      mxlc.dwLineID = mxl.dwLineID;
      
      // MIXERCONTROL_CONTROLTYPE_VOLUME
      // MIXERCONTROL_CONTROLTYPE_PEAKMETER
      // MIXERCONTROL_CONTROLTYPE_MUTE
      mxlc.dwControlType = MIXERCONTROL_CONTROLTYPE_VOLUME;
      mxlc.cControls = 1;
      mxlc.cbmxctrl = sizeof(mxc);
      mxlc.pamxctrl = &mxc;
      ZeroMemory(&mxc, sizeof(mxc));
      mxc.cbStruct = sizeof(MIXERCONTROL);
      rc = mixerGetLineControls((HMIXEROBJ)hMixer,&mxlc,
      MIXER_GETLINECONTROLSF_ONEBYTYPE);
      if (MMSYSERR_NOERROR != rc) {
          // Couldn't get the control.
        printf("bad2 fatal");
        return -1;
      }
      
   
  // After successfully getting the peakmeter control, the volume range
    // will be specified by mxc.Bounds.lMinimum to mxc.Bounds.lMaximum.

    MIXERCONTROLDETAILS mxcd;             // Gets the control values.
    MIXERCONTROLDETAILS_SIGNED volStruct; // Gets the control values.
    long volume;                          // Holds the final volume value.

    // Initialize the MIXERCONTROLDETAILS structure
    ZeroMemory(&mxcd, sizeof(mxcd));
    ZeroMemory(&volStruct, sizeof(volStruct));
    mxcd.cbStruct = sizeof(MIXERCONTROL);
    mxcd.cbDetails = sizeof(volStruct);
    mxcd.dwControlID = mxc.dwControlID;
    mxcd.paDetails = &volStruct;
    mxcd.cChannels = 1;

    // Get the current value of the peakmeter control. Typically, you
    // would set a timer in your program to query the volume every 10th
    // of a second or so.
    rc = mixerGetControlDetails((HMIXEROBJ)hMixer, &mxcd,
                                 MIXER_GETCONTROLDETAILSF_VALUE);
    if (MMSYSERR_NOERROR == rc) {
        // Couldn't get the current volume.
      printf("bad1");
      return -1;
        
    }
    volume = volStruct.lValue;
    //volume =  mxc.Bounds.lMaximum;

    // Get the absolute value of the volume.
    if (volume < 0)
        volume = -volume;
              
      printf("it is %f", volume);
      return 0;
    }