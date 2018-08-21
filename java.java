import java.math.*;
import java.lang.reflect.*;
class F4 {
  public static void main(String[] args) {
    try {
      Constructor<?> Bignum = Class.forName("java.math.MutableBigInteger").getDeclaredConstructor(int.class);
      Bignum.setAccessible(true);
      Object i = Bignum.newInstance(1);
      Method m = i.getClass().getDeclaredMethod("mul", new Class[] { int.class, i.getClass()});
      m.setAccessible(true);
      for(int z=2; z<500000 ; ++z) {
        m.invoke(i, z, i);
      }
      System.out.println( i );
    } catch(Exception e) { System.err.println(e); } 
  }
}
