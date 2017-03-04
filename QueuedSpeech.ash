
#ifdef AGS_SUPPORTS_IFVER       
#ifver 3.2                      
#define QueuedSpeech_VERSION 3.5
#define QueuedSpeech_VERSION_350
#endif                          
#endif                          
#ifndef QueuedSpeech_VERSION    
#error QueuedSpeech module error: This module requires AGS version 3.2 or higher! Please upgrade to a higher version of AGS to use this module.
#endif                          

enum QueuedSpeech_Settings
{
  eQueuedSpeech_MaxLinesInQueue = 30
};

///QueuedSpeech module: Displays MESSAGE as background speech in a queued fashion.
import bool SayQueued(this Character*, String message, AudioClip *speechClip=0, int delay=0, int slot=SCR_NO_VALUE);

struct QueuedSpeech
{
  ///QueuedSpeech module: Completely clears the queue.
  import static void ClearQueue();
  ///QueuedSpeech module: Returns whether the queue is empty.
  import static bool IsQueueEmpty();
  ///QueuedSpeech module: Returns whether the queue is full.
  import static bool IsQueueFull();
  ///QueuedSpeech module: Returns the number of items currently in the queue.
  import static int GetItemCountInQueue();
  ///QueuedSpeech module: Removes the currently shown message and continues to the next one.
  import static void SkipCurrentMessage();
  ///QueuedSpeech module: Returns whether the queue is currently looping.
  import static bool IsLooping();
  ///QueuedSpeech module: Starts the queue looping through the items repeatedly.
  import static void StartLooping();
  ///QueuedSpeech module: Stops the queue looping through the items.
  import static void StopLooping();
  ///QueuedSpeech module: Returns the current index in the queue (used when looping).
  import static int GetCurrentIndex();
  ///QueuedSpeech module: Returns the Character for the specified slot in the queue.
  import static Character* GetCharacter(int slot);
  ///QueuedSpeech module: Returns the message for the specified slot in the queue.
  import static String GetMessage(int slot);
  ///QueuedSpeech module: Returns the speech clip (see documentation!) for the specified slot in the queue.
  import static AudioClip* GetSpeechClip(int slot);
  ///QueuedSpeech module: Returns the delay for the specified slot in the queue.
  import static int GetDelay(int slot);
  ///QueuedSpeech module: Temporarily pauses the queue from running.
  import static void PauseQueue();
  ///QueuedSpeech module: Resumes the queue from a pause.
  import static void UnPauseQueue();
};
