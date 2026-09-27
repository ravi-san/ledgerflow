import { useEffect } from "react";
import { createConsumer } from "@rails/actioncable";
import { API_URL } from "../services/api";

export function useTeamCable(token, teamId, onMessage) {
  useEffect(() => {
    if (!token || !teamId) return undefined;
    const consumer = createConsumer(`${API_URL.replace(/^http/, "ws")}/cable?token=${encodeURIComponent(token)}`);
    const subscription = consumer.subscriptions.create({ channel: "TeamChannel", team_id: teamId }, { received: onMessage });
    return () => { subscription.unsubscribe(); consumer.disconnect(); };
  }, [token, teamId, onMessage]);
}
