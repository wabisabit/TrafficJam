int w = 600;
int h = 600;

TheModule Module;
  
void setup() {
  size(600, 600);
  smooth();
  Module = new TrafficJam();
  Module.setMeUp();
}

void draw() {
  Module.updateMe();
  Module.drawMe();
  image(Module.p, 0, 0);
  if ((frameCount % 150) == 0) {
    Module.refreshData();
  }
}  
class TheModule {
  PGraphics p;
  TheModule() { 
    p = createGraphics(w, h, JAVA2D);
  }
  void setMeUp() { }
  void refreshData() { }
  void updateMe() { }
  void drawMe() { }
}

class RetrieveData {
  
  String module_name;
  String [] data;
  String [][] csv;
  
  int num_columns = 0;
  
  RetrieveData(String mod_name) {
    module_name = mod_name;
    refreshData();
  }
  
  void refreshData() {
    String [] data = loadStrings("http://citydashboard.org/modules/" + module_name + ".php?city=london&format=csv");
    
   
    for (int i=0; i < data.length; i++) {
      String [] chars = split(data[i], ',');
      if (chars.length > num_columns) {
        num_columns = chars.length;
      }
    }
       
    csv = new String [data.length][num_columns];
    for (int i=0; i < data.length; i++) {
      String [] temp =  split(data[i], ',');
      for (int j = 0; j < temp.length; j++) {
        csv[i][j] = temp[j];
      }
    }
  }
  
  String getData(int row, int column) {
    return csv[row][column];
  }
  
  float getDataFloat(int row, int column) {
    return float(getData(row, column));
  }
}



