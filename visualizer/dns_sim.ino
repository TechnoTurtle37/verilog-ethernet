int randNo = 0;
int randCount = 0;
String urls[11] = {"youtube.com", "google.com", "yahoo.com", "gatech.edu", "stackoverflow.com", "sparkfun.com", "w3schools.com", "outlook.com", "reddit.com", "linkedin.com", "twitter.com"};

void setup() {
  Serial.begin(115200);
  
}

// Randomly generates simulated data expected as output from the DE2-115.
// The data is in the form "URL, # of queries"
void loop() {
  randNo = random(0, 10);
  randCount = random(0, 101);
  Serial.print(urls[randNo]);
  Serial.print(", ");
  Serial.print(randCount);
  Serial.print("\n");

  delay(1000);
  
}
