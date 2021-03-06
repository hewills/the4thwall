AGSScriptModule    monkey_05_06 Allows for queued background speech with animation and voice speech support. QueuedSpeech 3.0 �%  
struct QueuedSpeech_QueueType
{
  Character *AGSCharacter[eQueuedSpeech_MaxLinesInQueue]; // speaking character
  Overlay *AGSOverlay; // pointer to keep the overlay in scope
  int Delay[eQueuedSpeech_MaxLinesInQueue]; // delay for each item
  int DelayTimer; // timer to count down current delay
  int Index; // current index (used for looping)
  bool Looping; // whether the queue is looping
  String Messages[eQueuedSpeech_MaxLinesInQueue]; // messages to be displayed
  int MessageCount; // number of messages currently used by the queue
  bool Paused; // whether the queue is currently paused
  AudioChannel *SpeechChannel; // channel speech clip is playing on
  AudioClip *SpeechClip[eQueuedSpeech_MaxLinesInQueue]; // speech clip to play
  int SpeechTimer; // timer for displaying speech
  import void Next(); // updates the queue for the next item
  import void RemoveFirstItem(); // removes first item from the queue
};

QueuedSpeech_QueueType QueuedSpeech_Queue;

void QueuedSpeech_QueueType::RemoveFirstItem()
{
  if (!this.MessageCount) return;
  int i = 1;
  while (i < eQueuedSpeech_MaxLinesInQueue)
  {
    this.AGSCharacter[i - 1] = this.AGSCharacter[i];
    this.Delay[i - 1] = this.Delay[i];
    this.Messages[i - 1] = this.Messages[i];
    this.SpeechClip[i - 1] = this.SpeechClip[i];
    i++;
  }
  this.AGSCharacter[i - 1] = null;
  this.Delay[i - 1] = 0;
  this.Index = 0;
  this.Messages[i - 1] = null;
  this.MessageCount--;
  this.SpeechClip[i - 1] = null;
}

void QueuedSpeech_QueueType::Next()
{
  if ((this.AGSOverlay != null) && (this.AGSOverlay.Valid)) this.AGSOverlay.Remove();
  this.AGSOverlay = null;
  if (this.AGSCharacter[this.Index] != null) this.AGSCharacter[this.Index].UnlockView();
  this.DelayTimer = 0;
  if (this.Looping)
  {
    this.Index++;
    if (this.Index >= QueuedSpeech_Queue.MessageCount) this.Index = 0;
  }
  else this.RemoveFirstItem();
  if (this.SpeechChannel != null) this.SpeechChannel.Stop();
  this.SpeechChannel = null;
  this.SpeechTimer = 0;
}

function game_start()
{
  QueuedSpeech_Queue.SpeechChannel = null;
}

bool Insert(this QueuedSpeech_QueueType*, int slot, Character *theCharacter, String message, AudioClip *speechClip, int delay)
{
  if ((String.IsNullOrEmpty(message)) || (this.MessageCount == eQueuedSpeech_MaxLinesInQueue)) return false;
  if ((slot < 0) || (slot > this.MessageCount)) slot = this.MessageCount;
  int i = this.MessageCount;
  while (i > slot) // copy items after specified slot to the subsequent slot
  {
    this.AGSCharacter[i + 1] = this.AGSCharacter[i];
    this.Delay[i + 1] = this.Delay[i];
    this.Messages[i + 1] = this.Messages[i];
    this.SpeechClip[i + 1] = this.SpeechClip[i];
    i--;
  }
  this.AGSCharacter[slot] = theCharacter;
  this.Delay[slot] = delay;
  this.Messages[slot] = message;
  this.SpeechClip[slot] = speechClip;
  this.MessageCount++;
  return true;
}

bool SayQueued(this Character*, String message, AudioClip *speechClip, int delay, int slot)
{
  if (delay < 0) delay = 0;
  else if (delay > 150000) delay = 150000;
  return QueuedSpeech_Queue.Insert(slot, this, message, speechClip, delay);
}

Overlay* OverlayCreateTextualAligned(int x, int y, int width, FontType font, int color, String message, Alignment align)
{
  int height = GetTextHeight(message, font, width);
  DynamicSprite *sprite = DynamicSprite.Create(width, height);
  DrawingSurface *surface = sprite.GetDrawingSurface();
  surface.DrawingColor = color;
  surface.DrawStringWrapped(0, 0, width, font, align, message);
  surface.Release();
  Overlay *newOverlay = Overlay.CreateGraphical(x, y, sprite.Graphic, true);
  sprite.Delete();
  return newOverlay;
}

void BuildOverlay(this Character*, String message)
{
  int width = GetTextWidth(message, Game.SpeechFont);
  int d = ((System.ViewportWidth / 6) * 4);
  if ((this.x <= (System.ViewportWidth / 4)) || (this.x >= ((System.ViewportWidth / 4) * 3))) d -= (System.ViewportWidth / 5);
  if (width > d) width = d;
  int x = (this.x - (width / 2)) - 6;
  width += 6;
  if ((x + width) > System.ViewportWidth) x = (System.ViewportWidth - width);
  if (x < 0) x = 0;
  int height = GetTextHeight(message, Game.SpeechFont, width);
  ViewFrame *frame = Game.GetViewFrame(this.View, this.Loop, this.Frame);
  int y = (this.y - (((Game.SpriteHeight[frame.Graphic] * this.Scaling) / 100) + height + 2)) - 6;
  if ((y < 0) || ((y + height) > System.ViewportHeight)) y = (System.ViewportHeight - height);
  QueuedSpeech_Queue.AGSOverlay = OverlayCreateTextualAligned(x, y, width, Game.SpeechFont, this.SpeechColor, message, eAlignCentre);
  QueuedSpeech_Queue.SpeechTimer = ((message.Length / Game.TextReadingSpeed) + 1) * GetGameSpeed();
  if (QueuedSpeech_Queue.SpeechTimer < (Game.MinimumTextDisplayTimeMs / 1000)) QueuedSpeech_Queue.SpeechTimer = (Game.MinimumTextDisplayTimeMs / 1000);
}

function repeatedly_execute_always()
{
  if (QueuedSpeech_Queue.Paused)
  {
    // if the queue is paused, make sure the currently displayed item is still properly cleared
    if (((QueuedSpeech_Queue.SpeechChannel != null) && (!QueuedSpeech_Queue.SpeechChannel.IsPlaying)) ||
        ((QueuedSpeech_Queue.SpeechClip[QueuedSpeech_Queue.Index] == null) && (!QueuedSpeech_Queue.SpeechTimer)))
    {
      QueuedSpeech_Queue.Next();
    }
    else if (QueuedSpeech_Queue.SpeechTimer) QueuedSpeech_Queue.SpeechTimer--;
  }
}

function repeatedly_execute()
{
  if (QueuedSpeech_Queue.MessageCount == 0) return;
  int n = QueuedSpeech_Queue.Index;
  // if there is delay but the timer is not set, then set the delay timer
  if ((QueuedSpeech_Queue.Delay[n]) && (!QueuedSpeech_Queue.DelayTimer)) QueuedSpeech_Queue.DelayTimer = QueuedSpeech_Queue.Delay[n];
  if (QueuedSpeech_Queue.DelayTimer > 0) // update delay timer
  {
    QueuedSpeech_Queue.DelayTimer--;
    if (!QueuedSpeech_Queue.DelayTimer) QueuedSpeech_Queue.DelayTimer--; // use -1 to show the delay timer is finished
    return; // delay, so don't process the next item yet
  }
  Character *theCharacter = QueuedSpeech_Queue.AGSCharacter[n];
  if (!theCharacter.Animating)
  {
    if (theCharacter.SpeechView) theCharacter.LockView(theCharacter.SpeechView);
    else theCharacter.LockView(theCharacter.View);
    theCharacter.Animate(theCharacter.Loop, theCharacter.SpeechAnimationDelay, eRepeat, eNoBlock, eForwards);
  }
  if (QueuedSpeech_Queue.AGSOverlay == null)
  {
    theCharacter.BuildOverlay(QueuedSpeech_Queue.Messages[n]);
    if (QueuedSpeech_Queue.SpeechClip[n] != null) QueuedSpeech_Queue.SpeechChannel = QueuedSpeech_Queue.SpeechClip[n].Play();
  }
  else if (((QueuedSpeech_Queue.SpeechChannel != null) && (!QueuedSpeech_Queue.SpeechChannel.IsPlaying)) ||
           ((QueuedSpeech_Queue.SpeechClip[QueuedSpeech_Queue.Index] == null) && (!QueuedSpeech_Queue.SpeechTimer)))
  {
    QueuedSpeech_Queue.Next();
  }
  else if (QueuedSpeech_Queue.SpeechTimer) QueuedSpeech_Queue.SpeechTimer--;
}

static void QueuedSpeech::ClearQueue()
{
  int i = 0;
  while (i < eQueuedSpeech_MaxLinesInQueue)
  {
    QueuedSpeech_Queue.AGSCharacter[i] = null;
    QueuedSpeech_Queue.Delay[i] = 0;
    QueuedSpeech_Queue.Messages[i] = null;
    QueuedSpeech_Queue.SpeechClip[i] = null;
    i++;
  }
  if ((QueuedSpeech_Queue.AGSOverlay != null) && (QueuedSpeech_Queue.AGSOverlay.Valid)) QueuedSpeech_Queue.AGSOverlay.Remove();
  QueuedSpeech_Queue.AGSOverlay = null;
  QueuedSpeech_Queue.DelayTimer = 0;
  QueuedSpeech_Queue.Index = 0;
  QueuedSpeech_Queue.Looping = false;
  QueuedSpeech_Queue.MessageCount = 0;
  if ((QueuedSpeech_Queue.SpeechChannel != null) && (QueuedSpeech_Queue.SpeechChannel.IsPlaying)) QueuedSpeech_Queue.SpeechChannel.Stop();
  QueuedSpeech_Queue.SpeechChannel = null;
  QueuedSpeech_Queue.SpeechTimer = 0;
}

static Character* QueuedSpeech::GetCharacter(int slot)
{
  if ((slot < 0) || (slot >= QueuedSpeech_Queue.MessageCount)) return null;
  return QueuedSpeech_Queue.AGSCharacter[slot];
}

static int QueuedSpeech::GetCurrentIndex()
{
  return QueuedSpeech_Queue.Index;
}

static int QueuedSpeech::GetDelay(int slot)
{
  if ((slot < 0) || (slot >= QueuedSpeech_Queue.MessageCount)) return 0;
  return QueuedSpeech_Queue.Delay[slot];
}

static int QueuedSpeech::GetItemCountInQueue()
{
  return QueuedSpeech_Queue.MessageCount;
}

static String QueuedSpeech::GetMessage(int slot)
{
  if ((slot < 0) || (slot >= QueuedSpeech_Queue.MessageCount)) return null;
  return QueuedSpeech_Queue.Messages[slot];
}

static AudioClip* QueuedSpeech::GetSpeechClip(int slot)
{
  if ((slot < 0) || (slot >= QueuedSpeech_Queue.MessageCount)) return null;
  return QueuedSpeech_Queue.SpeechClip[slot];
}

static bool QueuedSpeech::IsLooping()
{
  return QueuedSpeech_Queue.Looping;
}

static bool QueuedSpeech::IsQueueEmpty()
{
  return (!QueuedSpeech_Queue.MessageCount);
}

static bool QueuedSpeech::IsQueueFull()
{
  return (QueuedSpeech_Queue.MessageCount == eQueuedSpeech_MaxLinesInQueue);
}

static void QueuedSpeech::PauseQueue()
{
  QueuedSpeech_Queue.Paused = true;
}

static void QueuedSpeech::SkipCurrentMessage()
{
  QueuedSpeech_Queue.Next();
}

static void QueuedSpeech::StartLooping()
{
  QueuedSpeech_Queue.Looping = true;
}

static void QueuedSpeech::StopLooping()
{
  QueuedSpeech_Queue.Looping = false;
  int n = QueuedSpeech_Queue.Index;
  int i = 0;
  while (i < n)
  {
    QueuedSpeech_Queue.RemoveFirstItem();
    i++;
  }
}

static void QueuedSpeech::UnPauseQueue()
{
  QueuedSpeech_Queue.Paused = false;
}
 �	  
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
 	��        ej��