import React from "react";

interface Props {
    spectating: boolean;
    spectatorTarget: string;
}

const Spectator: React.FC<Props> = ({ spectating, spectatorTarget }) => {
    return (
        <>
            {(spectating === true) &&
                <div id="pageInGame" className="page">
                    <div className={"infoBox notReady"}>
                        <h1>{spectatorTarget??''}</h1>
                        <h3>Spectating</h3>
                    </div>
                </div>
            }
        </>
    );
};

export default Spectator;
