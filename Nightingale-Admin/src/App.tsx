import { Button } from "@/components/ui/button";
import { database } from "@/lib/firebase";
import { ref, get } from "firebase/database";

const App = () => {
  const handleFetchData = async () => {
    try {
      const [soundcloudSnapshot, firebaseSnapshot, usersAllowedSnapshot] = await Promise.all([
        get(ref(database, "soundcloudSongs")),
        get(ref(database, "firebaseSongs")),
        get(ref(database, "usersAllowedFirebaseSongs")),
      ]);

      const soundcloudSongs = soundcloudSnapshot.val();
      const firebaseSongs = firebaseSnapshot.val();
      const usersAllowedFirebaseSongs = usersAllowedSnapshot.val();

      console.log("Soundcloud Songs:", soundcloudSongs);
      console.log("Firebase Songs:", firebaseSongs);
      console.log("Users Allowed Firebase Songs:", usersAllowedFirebaseSongs);
    } catch (error) {
      console.error("Error fetching data:", error);
    }
  };

  return (
    <div className="flex min-h-svh flex-col items-center justify-center">
      <Button onClick={handleFetchData}>Fetch Songs</Button>
    </div>
  );
};

export default App;
