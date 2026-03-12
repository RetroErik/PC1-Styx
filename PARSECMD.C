/* Styx Remastered
   Copyright (c) Andrew Jenner 1998-2004 */

void printhelp(void);
void exit(void);
void quiet(void);
void setmode(int mode);
void setspeedmul(int speedmul);

void parsecmd(char far *input)
{
  char word[128];
  int i,j,speedmul;
  char far *p=input;
  do {
    while (*p==' ')
      p++;
    i=0;
    while (*p!=' ' && *p!=13)
      word[i++]=*(p++);
    word[i]=0;
    if (word[0]=='/' || word[0]=='-') {
      if (word[1]=='S' || word[1]=='s')
        if (word[2]==':')
          i=3;
        else
          i=2;
      if (word[1]=='S' || word[1]=='s') {
        speedmul=0;
        while (word[i]!=0)
          speedmul=10*speedmul+word[i++]-'0';
        setspeedmul(speedmul);
      }
      if (word[1]=='?' || word[1]=='h' || word[1]=='H') {
        printhelp();
        exit();
      }
      if (word[1]=='C' || word[1]=='c')
        setmode(1);
      if (word[1]=='V' || word[1]=='v')
        setmode(2);
      if (word[1]=='Q' || word[1]=='q')
        quiet();
    }
    else {
      if (i<1)
        continue;
      speedmul=0;
      j=0;
      while (word[j]!=0)
        speedmul=10*speedmul+word[j++]-'0';
      setspeedmul(speedmul);
    }
  } while (*p!=13);
}
